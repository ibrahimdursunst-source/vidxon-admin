import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/audit/domain/admin_audit_entry.dart';
import 'package:vidxon_admin/features/audit/presentation/admin_audit_page.dart';
import 'package:vidxon_admin/features/admin_context/domain/admin_current_context.dart';
import 'package:vidxon_admin/features/admin_context/presentation/admin_context_scope.dart';
import 'package:vidxon_admin/features/audit/data/admin_audit_repository.dart';

const _actorId = '11111111-1111-1111-1111-111111111111';

AdminCurrentContext _adminContext() {
  return AdminCurrentContext.fromMap({
    'user_id': _actorId,
    'role': 'admin',
    'is_super_admin': false,
  });
}

class _FakeAuditRepository extends AdminAuditRepository {
  _FakeAuditRepository(this.entries) : super(client: null);

  final List<AdminAuditEntry> entries;

  @override
  Future<List<AdminAuditEntry>> listAuditLog({
    String? actionType,
    String? targetUserId,
    int limit = 50,
    int offset = 0,
  }) async {
    return entries;
  }
}

AdminAuditEntry _contentEntry(String action, {Map<String, dynamic>? metadata}) {
  return AdminAuditEntry.fromMap({
    'audit_id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'action_type': action,
    'created_at': '2026-08-01T10:00:00.000Z',
    'metadata': metadata ?? const {},
  });
}

Widget _wrap(AdminAuditRepository repository) {
  return MaterialApp(
    home: AdminContextScope(
      contextResult: AdminContextLoadResult.loaded(_adminContext()),
      child: Scaffold(body: AdminAuditPage(repository: repository)),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdminAuditEntry content labels', () {
    final cases = <String, String>{
      AdminAuditActionType.seriesCreated: 'Dizi Oluşturuldu',
      AdminAuditActionType.seriesUpdated: 'Dizi Güncellendi',
      AdminAuditActionType.seriesPosterReplaced: 'Poster Değiştirildi',
      AdminAuditActionType.seriesPublished: 'Dizi Yayınlandı',
      AdminAuditActionType.seriesUnpublished: 'Dizi Yayından Kaldırıldı',
      AdminAuditActionType.seriesArchived: 'Dizi Arşivlendi',
      AdminAuditActionType.seriesRestored: 'Dizi Geri Yüklendi',
      AdminAuditActionType.episodeCreated: 'Bölüm Oluşturuldu',
      AdminAuditActionType.episodeUpdated: 'Bölüm Güncellendi',
      AdminAuditActionType.episodesReordered: 'Bölüm Sıralaması Değiştirildi',
      AdminAuditActionType.episodeStreamAttached: 'Video Bağlandı',
      AdminAuditActionType.episodeStreamReplacementRequested:
          'Video Değişimi İstendi',
      AdminAuditActionType.episodeStreamPromoted: 'Video Aktif Edildi',
    };

    for (final entry in cases.entries) {
      test('labels ${entry.key}', () {
        expect(AdminAuditActionType.labelFor(entry.key), entry.value);
      });
    }

    test('unknown action falls back to raw action', () {
      expect(
        AdminAuditActionType.labelFor('content.unknown_action'),
        'content.unknown_action',
      );
    });

    test('null metadata does not crash summary', () {
      final entry = AdminAuditEntry.fromMap({
        'audit_id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        'action_type': AdminAuditActionType.seriesUpdated,
        'created_at': '2026-08-01T10:00:00.000Z',
        'metadata': null,
      });

      expect(entry.summaryLabel, 'Dizi Güncellendi');
    });

    test('wallet labels remain unchanged', () {
      expect(
        AdminAuditActionType.labelFor(AdminAuditActionType.walletCredit),
        'Jeton Yükleme',
      );
    });
  });

  group('AdminAuditPage content presentation', () {
    testWidgets('renders content audit rows without raw JSON', (tester) async {
      final repository = _FakeAuditRepository([
        _contentEntry(
          AdminAuditActionType.seriesUpdated,
          metadata: {'new_title': 'Yeni Dizi'},
        ),
      ]);

      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_wrap(repository));
      await tester.pumpAndSettle();

      expect(find.textContaining('Dizi Güncellendi'), findsWidgets);
      expect(find.textContaining('{'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders narrow width without overflow', (tester) async {
      final repository = _FakeAuditRepository([
        _contentEntry(AdminAuditActionType.episodePublished),
      ]);

      await tester.binding.setSurfaceSize(const Size(480, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_wrap(repository));
      await tester.pumpAndSettle();

      expect(find.text('Bölüm Yayınlandı'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
