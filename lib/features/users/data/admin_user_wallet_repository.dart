import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/admin_coin_credit_input.dart';
import '../domain/admin_coin_credit_result.dart';
import '../domain/admin_user_details.dart';
import '../domain/admin_user_summary.dart';
import '../domain/admin_wallet_ledger_entry.dart';
import 'admin_user_wallet_errors.dart';

class AdminUserWalletRepository {
  AdminUserWalletRepository({this._client});

  final SupabaseClient? _client;

  SupabaseClient get _supabaseClient => _client ?? Supabase.instance.client;

  Future<List<AdminUserSummary>> searchUsers({
    String query = '',
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final result = await _supabaseClient.rpc(
        'admin_search_users',
        params: buildSearchUsersRpcParams(
          query: query,
          limit: limit,
          offset: offset,
        ),
      );

      final rows = parseRpcListResult(result);
      return rows.map(AdminUserSummary.fromMap).toList(growable: false);
    } on AdminUserWalletException {
      rethrow;
    } on PostgrestException catch (error) {
      throw AdminUserWalletErrorMapper.fromPostgrest(error);
    } on FormatException {
      throw AdminUserWalletException(
        message: 'Kullanıcı listesi yanıtı geçersiz.',
        kind: AdminUserWalletFailureKind.serverError,
      );
    } catch (_) {
      throw AdminUserWalletException(
        message: 'Ağ bağlantısı kesildi. Lütfen tekrar deneyin.',
        kind: AdminUserWalletFailureKind.networkError,
      );
    }
  }

  Future<AdminUserDetails> getUserDetails({required String userId}) async {
    try {
      final result = await _supabaseClient.rpc(
        'admin_get_user_details',
        params: buildGetUserDetailsRpcParams(userId: userId),
      );

      return AdminUserDetails.fromMap(
        parseRpcMapResult(
          result,
          emptyResultKind: AdminUserWalletFailureKind.userNotFound,
          emptyResultMessage: 'Kullanıcı bulunamadı.',
        ),
      );
    } on AdminUserWalletException {
      rethrow;
    } on PostgrestException catch (error) {
      throw AdminUserWalletErrorMapper.fromPostgrest(error);
    } on FormatException {
      throw AdminUserWalletException(
        message: 'Kullanıcı detayı yanıtı geçersiz.',
        kind: AdminUserWalletFailureKind.serverError,
      );
    } catch (_) {
      throw AdminUserWalletException(
        message: 'Ağ bağlantısı kesildi. Lütfen tekrar deneyin.',
        kind: AdminUserWalletFailureKind.networkError,
      );
    }
  }

  Future<List<AdminWalletLedgerEntry>> listUserWalletLedger({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final result = await _supabaseClient.rpc(
        'admin_list_user_wallet_ledger',
        params: buildListUserWalletLedgerRpcParams(
          userId: userId,
          limit: limit,
          offset: offset,
        ),
      );

      final rows = parseRpcListResult(result);
      return rows.map(AdminWalletLedgerEntry.fromMap).toList(growable: false);
    } on AdminUserWalletException {
      rethrow;
    } on PostgrestException catch (error) {
      throw AdminUserWalletErrorMapper.fromPostgrest(error);
    } on FormatException {
      throw AdminUserWalletException(
        message: 'Cüzdan geçmişi yanıtı geçersiz.',
        kind: AdminUserWalletFailureKind.serverError,
      );
    } catch (_) {
      throw AdminUserWalletException(
        message: 'Ağ bağlantısı kesildi. Lütfen tekrar deneyin.',
        kind: AdminUserWalletFailureKind.networkError,
      );
    }
  }

  Future<AdminCoinCreditResult> creditUserCoins({
    required AdminCoinCreditInput input,
    required String idempotencyKey,
  }) async {
    try {
      final result = await _supabaseClient.rpc(
        'admin_credit_user_coins',
        params: buildCreditUserCoinsRpcParams(
          input: input,
          idempotencyKey: idempotencyKey,
        ),
      );

      return AdminCoinCreditResult.fromMap(parseRpcMapResult(result));
    } on AdminUserWalletException {
      rethrow;
    } on PostgrestException catch (error) {
      throw AdminUserWalletErrorMapper.fromPostgrest(error);
    } on FormatException {
      throw AdminUserWalletException(
        message: 'Jeton yükleme yanıtı geçersiz.',
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
