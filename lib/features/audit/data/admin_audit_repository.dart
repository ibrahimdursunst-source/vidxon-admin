import 'package:supabase_flutter/supabase_flutter.dart';

import '../../users/data/admin_user_wallet_errors.dart';
import '../domain/admin_audit_entry.dart';

class AdminAuditRepository {
  AdminAuditRepository({this._client});

  final SupabaseClient? _client;

  SupabaseClient get _supabaseClient => _client ?? Supabase.instance.client;

  Future<List<AdminAuditEntry>> listAuditLog({
    String? actionType,
    String? targetUserId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final result = await _supabaseClient.rpc(
        'admin_list_audit_log',
        params: buildListAuditLogRpcParams(
          actionType: actionType,
          targetUserId: targetUserId,
          limit: limit,
          offset: offset,
        ),
      );

      final rows = parseRpcListResult(result);
      return rows.map(AdminAuditEntry.fromMap).toList(growable: false);
    } on AdminUserWalletException {
      rethrow;
    } on PostgrestException catch (error) {
      throw AdminUserWalletErrorMapper.fromPostgrest(error);
    } on FormatException {
      throw AdminUserWalletException(
        message: 'İşlem kayıtları yanıtı geçersiz.',
        kind: AdminUserWalletFailureKind.serverError,
      );
    } catch (_) {
      throw AdminUserWalletException(
        message: 'Ağ bağlantısı kesildi. Lütfen tekrar deneyin.',
        kind: AdminUserWalletFailureKind.networkError,
      );
    }
  }
}
