import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/partners/data/partner_errors.dart';
import 'package:vidxon_admin/features/partners/data/partner_repository.dart';
import 'package:vidxon_admin/features/partners/domain/admin_partner_detail.dart';
import 'package:vidxon_admin/features/partners/domain/admin_partner_member.dart';

import 'partner_test_helpers.dart';

void main() {
  group('Partner mutation integrity', () {
    test('I. member canonical lookup preserves backend created_at', () {
      final detail = AdminPartnerDetail.fromMap(
        partnerDetailJson(members: [partnerMemberJson()]),
      );

      final member = AdminPartnerMember.requireFromDetail(detail, testUserId);

      expect(member.createdAt.toIso8601String(), testCreatedAt);
      expect(
        member.createdAt,
        isNot(DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)),
      );
    });

    test(
      'I. add-member write ack lacks created_at and canonical detail supplies it',
      () {
        final ack = partnerAddMemberWriteAckJson();
        expect(ack.containsKey('created_at'), isFalse);

        final parsedAck = parsePartnerRpcMap(ack);
        expect(parsedAck['partner_id'], testPartnerId);
        expect(parsedAck['user_id'], testUserId);

        final detail = AdminPartnerDetail.fromMap(
          partnerDetailJson(members: [partnerMemberJson()]),
        );
        final member = requireCanonicalMemberForTesting(detail, testUserId);

        expect(member.createdAt.toIso8601String(), testCreatedAt);
      },
    );

    test(
      'I. partner write path does not fabricate backend timestamps',
      () {
        final repoRoot = Directory.current.path;
        final paths = [
          '$repoRoot/lib/features/partners/data/partner_repository.dart',
          '$repoRoot/lib/features/partners/domain/admin_partner_member.dart',
          '$repoRoot/lib/features/partners/domain/admin_partner_summary.dart',
        ];

        for (final path in paths) {
          final source = File(path).readAsStringSync();
          expect(
            source.contains('DateTime.now'),
            isFalse,
            reason: '$path must not synthesize timestamps',
          );
          expect(
            source.contains('fromWriteMap'),
            isFalse,
            reason: '$path must not use write-map timestamp fallback',
          );
          expect(
            source.contains('fromMutationMap'),
            isFalse,
            reason: '$path must not use mutation-map timestamp fallback',
          );
        }
      },
    );

    test('J. mutation ok:false remains fail-closed', () {
      expect(
        () => parsePartnerRpcMap(const {
          'ok': false,
          'partner_id': testPartnerId,
        }),
        throwsA(isA<PartnerException>()),
      );
    });

    test(
      'addMember returns canonical member when detail includes the user',
      () async {
        final repository = _MemberMutationProbeRepository(
          writeAck: partnerAddMemberWriteAckJson(),
          detail: AdminPartnerDetail.fromMap(
            partnerDetailJson(members: [partnerMemberJson()]),
          ),
        );

        final member = await repository.addMember(
          partnerId: testPartnerId,
          userId: testUserId,
        );

        expect(member.userId, testUserId);
        expect(member.createdAt.toIso8601String(), testCreatedAt);
      },
    );

    test(
      'addMember maps missing canonical member to PartnerException',
      () async {
        final repository = _MemberMutationProbeRepository(
          writeAck: partnerAddMemberWriteAckJson(),
          detail: AdminPartnerDetail.fromMap(
            partnerDetailJson(members: const []),
          ),
        );

        await expectLater(
          repository.addMember(partnerId: testPartnerId, userId: testUserId),
          throwsA(
            isA<PartnerException>()
                .having(
                  (error) => error.kind,
                  'kind',
                  PartnerFailureKind.parseError,
                )
                .having(
                  (error) => error.message,
                  'message',
                  contains('Partner yanıtı geçersiz'),
                ),
          ),
        );
      },
    );

    test('addMember ok:false remains fail-closed', () async {
      final repository = _MemberMutationProbeRepository(
        writeAck: const {
          'ok': false,
          'partner_id': testPartnerId,
          'user_id': testUserId,
        },
        detail: AdminPartnerDetail.fromMap(partnerDetailJson()),
      );

      await expectLater(
        repository.addMember(partnerId: testPartnerId, userId: testUserId),
        throwsA(isA<PartnerException>()),
      );
    });
  });
}

class _MemberMutationProbeRepository extends PartnerRepository {
  _MemberMutationProbeRepository({
    required this.writeAck,
    required this.detail,
  }) : super(client: null);

  final Map<String, dynamic> writeAck;
  final AdminPartnerDetail detail;

  @override
  Future<AdminPartnerDetail> fetchPartnerDetail(String partnerId) async {
    return detail;
  }

  @override
  Future<AdminPartnerMember> addMember({
    required String partnerId,
    required String userId,
  }) async {
    final map = parsePartnerRpcMap(writeAck);
    final ackPartnerId = map['partner_id'] as String;
    final ackUserId = map['user_id'] as String;
    if (ackPartnerId != partnerId.trim() || ackUserId != userId.trim()) {
      throw PartnerErrorMapper.parseFailure('Write ack mismatch.');
    }

    final fetched = await fetchPartnerDetail(partnerId);
    return requireCanonicalMemberForTesting(fetched, userId);
  }
}
