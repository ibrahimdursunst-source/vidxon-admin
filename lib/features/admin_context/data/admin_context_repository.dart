import 'package:supabase_flutter/supabase_flutter.dart';

import '../../users/data/admin_user_wallet_errors.dart';
import '../domain/admin_current_context.dart';

class AdminContextRepository {
  AdminContextRepository({this._client});

  final SupabaseClient? _client;

  SupabaseClient get _supabaseClient => _client ?? Supabase.instance.client;

  Future<AdminCurrentContext> getCurrentContext() async {
    try {
      final result = await _supabaseClient.rpc('admin_get_current_context');

      return AdminCurrentContext.fromMap(parseRpcMapResult(result));
    } on AdminUserWalletException {
      rethrow;
    } on PostgrestException catch (error) {
      throw AdminUserWalletErrorMapper.fromPostgrest(error);
    } on FormatException {
      throw AdminUserWalletException(
        message: 'Admin oturum bilgisi geçersiz.',
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
