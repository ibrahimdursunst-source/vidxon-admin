import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/partners/domain/admin_partner_detail.dart';

import '../data/partner_test_helpers.dart';

void main() {
  group('AdminPartnerDetail strict admin_partner_detail_v1 parse', () {
    test('A. accepts members: [] and assignments: []', () {
      final detail = AdminPartnerDetail.fromMap(partnerDetailJson());

      expect(detail.members, isEmpty);
      expect(detail.assignments, isEmpty);
    });

    test('B. missing members fails', () {
      final payload = partnerDetailJson()..remove('members');

      expect(
        () => AdminPartnerDetail.fromMap(payload),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'members is required.',
          ),
        ),
      );
    });

    test('C. members: null fails', () {
      final payload = partnerDetailJson()..['members'] = null;

      expect(
        () => AdminPartnerDetail.fromMap(payload),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'members is invalid.',
          ),
        ),
      );
    });

    test('D. wrong-type members fails', () {
      final payload = partnerDetailJson()..['members'] = 'bad';

      expect(
        () => AdminPartnerDetail.fromMap(payload),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'members is invalid.',
          ),
        ),
      );
    });

    test('E. missing assignments fails', () {
      final payload = partnerDetailJson()..remove('assignments');

      expect(
        () => AdminPartnerDetail.fromMap(payload),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'assignments is required.',
          ),
        ),
      );
    });

    test('F. assignments: null fails', () {
      final payload = partnerDetailJson()..['assignments'] = null;

      expect(
        () => AdminPartnerDetail.fromMap(payload),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'assignments is invalid.',
          ),
        ),
      );
    });

    test('G. wrong-type assignments fails', () {
      final payload = partnerDetailJson()..['assignments'] = 42;

      expect(
        () => AdminPartnerDetail.fromMap(payload),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'assignments is invalid.',
          ),
        ),
      );
    });

    test('H. valid populated detail still parses', () {
      final detail = AdminPartnerDetail.fromMap(
        partnerDetailJson(
          members: [partnerMemberJson()],
          assignments: [assignmentListItemJson()],
        ),
      );

      expect(detail.id, testPartnerId);
      expect(detail.members, hasLength(1));
      expect(detail.members.single.userId, testUserId);
      expect(detail.members.single.createdAt.toIso8601String(), testCreatedAt);
      expect(detail.assignments, hasLength(1));
      expect(detail.assignments.single.id, testAssignmentId);
    });
  });
}
