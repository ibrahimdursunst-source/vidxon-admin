import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/audit/domain/admin_audit_entry.dart';

void main() {
  group('AdminAuditActionType', () {
    test('labels content lifecycle actions in Turkish', () {
      expect(
        AdminAuditActionType.labelFor(AdminAuditActionType.seriesCreated),
        'Dizi Oluşturuldu',
      );
      expect(
        AdminAuditActionType.labelFor(
          AdminAuditActionType.episodeStreamReplacementRequested,
        ),
        'Video Değişimi İstendi',
      );
      expect(
        AdminAuditActionType.labelFor(
          AdminAuditActionType.episodeStreamPromoted,
        ),
        'Video Aktif Edildi',
      );
    });

    test('falls back safely for unknown action', () {
      expect(
        AdminAuditActionType.labelFor('content.unknown_action'),
        'content.unknown_action',
      );
    });
  });

  group('AdminAuditEntry', () {
    test('summary uses metadata title without raw JSON dump', () {
      final entry = AdminAuditEntry.fromMap({
        'audit_id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        'action_type': AdminAuditActionType.seriesUpdated,
        'created_at': '2026-08-01T10:00:00.000Z',
        'metadata': {'new_title': 'Yeni Dizi'},
      });

      expect(entry.summaryLabel, 'Dizi Güncellendi · Yeni Dizi');
      expect(entry.isContentAction, isTrue);
    });

    test(
      'targetLabel reads content target from metadata when no wallet user',
      () {
        final entry = AdminAuditEntry.fromMap({
          'audit_id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          'action_type': AdminAuditActionType.episodeCreated,
          'created_at': '2026-08-01T10:00:00.000Z',
          'metadata': {'slug': 'pilot-bolum'},
        });

        expect(entry.targetLabel, 'pilot-bolum');
      },
    );

    test('wallet audit labels remain unchanged', () {
      expect(
        AdminAuditActionType.labelFor(AdminAuditActionType.walletCredit),
        'Jeton Yükleme',
      );
    });
  });
}
