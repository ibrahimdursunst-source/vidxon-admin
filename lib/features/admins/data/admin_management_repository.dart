import 'package:supabase_flutter/supabase_flutter.dart';

import '../../admin_context/domain/admin_role.dart';
import '../../users/data/admin_user_wallet_errors.dart';
import '../domain/admin_account_summary.dart';

class AdminManagementRepository {
  AdminManagementRepository({this._client});

  final SupabaseClient? _client;

  SupabaseClient get _supabaseClient => _client ?? Supabase.instance.client;

  Future<List<AdminAccountSummary>> listAdminUsers({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final result = await _supabaseClient.rpc(
        'super_admin_list_admin_users',
        params: buildListAdminUsersRpcParams(limit: limit, offset: offset),
      );

      final rows = parseRpcListResult(result);
      return rows.map(AdminAccountSummary.fromMap).toList(growable: false);
    } on AdminUserWalletException {
      rethrow;
    } on PostgrestException catch (error) {
      throw AdminUserWalletErrorMapper.fromPostgrest(error);
    } on FormatException {
      throw AdminUserWalletException(
        message: 'Yönetici listesi yanıtı geçersiz.',
        kind: AdminUserWalletFailureKind.serverError,
      );
    } catch (_) {
      throw AdminUserWalletException(
        message: 'Ağ bağlantısı kesildi. Lütfen tekrar deneyin.',
        kind: AdminUserWalletFailureKind.networkError,
      );
    }
  }

  Future<void> setAdminRole({
    required String userId,
    required AdminRole role,
  }) async {
    try {
      final result = await _supabaseClient.rpc(
        'super_admin_set_admin_role',
        params: buildSetAdminRoleRpcParams(userId: userId, role: role),
      );

      parseRpcVoidResult(result);
    } on AdminUserWalletException {
      rethrow;
    } on PostgrestException catch (error) {
      throw AdminUserWalletErrorMapper.fromPostgrest(error);
    } catch (_) {
      throw AdminUserWalletException(
        message: 'Ağ bağlantısı kesildi. Lütfen tekrar deneyin.',
        kind: AdminUserWalletFailureKind.networkError,
      );
    }
  }

  Future<void> revokeAdminAccess({required String userId}) async {
    try {
      final result = await _supabaseClient.rpc(
        'super_admin_revoke_admin_access',
        params: buildRevokeAdminAccessRpcParams(userId: userId),
      );

      parseRpcVoidResult(result);
    } on AdminUserWalletException {
      rethrow;
    } on PostgrestException catch (error) {
      throw AdminUserWalletErrorMapper.fromPostgrest(error);
    } catch (_) {
      throw AdminUserWalletException(
        message: 'Ağ bağlantısı kesildi. Lütfen tekrar deneyin.',
        kind: AdminUserWalletFailureKind.networkError,
      );
    }
  }
}
