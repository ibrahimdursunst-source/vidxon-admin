import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/admin_partner_detail.dart';
import '../domain/admin_partner_member.dart';
import '../domain/admin_partner_summary.dart';
import '../domain/partner_analytics_health.dart';
import '../domain/partner_analytics_report.dart';
import '../domain/partner_rpc_params.dart';
import '../domain/partner_series_assignment.dart';
import '../domain/partner_status.dart';
import 'partner_errors.dart';

class PartnerRepository {
  PartnerRepository({this._client});

  final SupabaseClient? _client;

  SupabaseClient get _resolvedClient => _client ?? Supabase.instance.client;

  Future<List<AdminPartnerSummary>> listPartners() async {
    return _runList(
      rpcName: 'admin_partner_list_v1',
      params: const {},
      mapper: AdminPartnerSummary.fromMap,
      failureMessage: 'Partner listesi yüklenemedi.',
    );
  }

  Future<List<AdminPartnerActiveOption>> listActivePartners() async {
    return _runList(
      rpcName: 'admin_list_active_partners_v1',
      params: const {},
      mapper: AdminPartnerActiveOption.fromMap,
      failureMessage: 'Aktif Partner listesi yüklenemedi.',
    );
  }

  Future<AdminPartnerDetail> fetchPartnerDetail(String partnerId) async {
    return _runMap(
      rpcName: 'admin_partner_detail_v1',
      params: buildPartnerDetailRpcParams(partnerId: partnerId),
      mapper: AdminPartnerDetail.fromMap,
      failureMessage: 'Partner detayı yüklenemedi.',
    );
  }

  Future<AdminPartnerSummary> createPartner({
    required String displayName,
    String? legalName,
  }) async {
    return _runMap(
      rpcName: 'admin_partner_create_v1',
      params: buildPartnerCreateRpcParams(
        displayName: displayName,
        legalName: legalName,
      ),
      mapper: AdminPartnerSummary.fromMap,
      failureMessage: 'Partner oluşturulamadı.',
    );
  }

  Future<AdminPartnerSummary> updatePartner({
    required String partnerId,
    required String displayName,
    required PartnerStatus status,
    String? legalName,
  }) async {
    return _runMap(
      rpcName: 'admin_partner_update_v1',
      params: buildPartnerUpdateRpcParams(
        partnerId: partnerId,
        displayName: displayName,
        status: status,
        legalName: legalName,
      ),
      mapper: AdminPartnerSummary.fromMap,
      failureMessage: 'Partner güncellenemedi.',
    );
  }

  Future<PartnerLookupUser> lookupUserByEmail(String email) async {
    return _runMap(
      rpcName: 'admin_partner_lookup_user_by_email_v1',
      params: buildPartnerLookupUserRpcParams(email: email),
      mapper: PartnerLookupUser.fromMap,
      failureMessage: 'Kullanıcı bulunamadı.',
    );
  }

  Future<AdminPartnerMember> addMember({
    required String partnerId,
    required String userId,
  }) async {
    return _runMap(
      rpcName: 'admin_partner_add_member_v1',
      params: buildPartnerAddMemberRpcParams(
        partnerId: partnerId,
        userId: userId,
      ),
      mapper: AdminPartnerMember.fromMap,
      failureMessage: 'Üye eklenemedi.',
    );
  }

  Future<AdminPartnerMember> setMemberStatus({
    required String partnerId,
    required String userId,
    required PartnerMemberStatus status,
  }) async {
    return _runMap(
      rpcName: 'admin_partner_set_member_status_v1',
      params: buildPartnerSetMemberStatusRpcParams(
        partnerId: partnerId,
        userId: userId,
        status: status,
      ),
      mapper: AdminPartnerMember.fromMap,
      failureMessage: 'Üye durumu güncellenemedi.',
    );
  }

  Future<List<PartnerSeriesAssignment>> fetchAssignmentHistory(
    String seriesId,
  ) async {
    return _runList(
      rpcName: 'admin_partner_assignment_history_v1',
      params: buildPartnerAssignmentHistoryRpcParams(seriesId: seriesId),
      mapper: PartnerSeriesAssignment.fromMap,
      failureMessage: 'Atama geçmişi yüklenemedi.',
    );
  }

  Future<SetSeriesPartnerResult> setSeriesPartner({
    required String seriesId,
    required String? partnerId,
    required int expectedContentVersion,
  }) async {
    return _runMap(
      rpcName: 'admin_set_series_partner_v1',
      params: buildSetSeriesPartnerRpcParams(
        seriesId: seriesId,
        partnerId: partnerId,
        expectedContentVersion: expectedContentVersion,
      ),
      mapper: SetSeriesPartnerResult.fromMap,
      failureMessage: 'Partner ataması güncellenemedi.',
    );
  }

  /// Strict-parses analytics. On parse/RPC failure throws [PartnerException]
  /// — never synthesizes a zero report.
  Future<PartnerAnalyticsReport> fetchSeriesAnalytics({
    required String partnerId,
    required String seriesId,
    required PartnerAnalyticsPreset preset,
    DateTime? customStart,
    DateTime? customEnd,
    DateTime? asOf,
    int episodeLimit = 500,
    int episodeOffset = 0,
  }) async {
    try {
      final result = await _resolvedClient.rpc(
        'admin_partner_series_analytics_v1',
        params: buildPartnerSeriesAnalyticsRpcParams(
          partnerId: partnerId,
          seriesId: seriesId,
          preset: preset,
          customStart: customStart,
          customEnd: customEnd,
          asOf: asOf,
          episodeLimit: episodeLimit,
          episodeOffset: episodeOffset,
        ),
      );

      final map = parsePartnerRpcMap(result);
      return PartnerAnalyticsReport.fromJson(map);
    } on PartnerException {
      rethrow;
    } on FormatException catch (error) {
      throw PartnerErrorMapper.parseFailure(error.message);
    } on PostgrestException catch (error) {
      throw PartnerErrorMapper.fromPostgrest(error);
    } catch (_) {
      throw const PartnerException(
        message: 'Analitik raporu yüklenemedi. Lütfen tekrar deneyin.',
        kind: PartnerFailureKind.networkError,
      );
    }
  }

  Future<PartnerAnalyticsHealth> fetchAnalyticsHealth() async {
    try {
      final result = await _resolvedClient.rpc(
        'admin_partner_analytics_health_v1',
      );
      final map = parsePartnerRpcMap(result);
      return PartnerAnalyticsHealth.fromJson(map);
    } on PartnerException {
      rethrow;
    } on FormatException catch (error) {
      throw PartnerErrorMapper.parseFailure(error.message);
    } on PostgrestException catch (error) {
      throw PartnerErrorMapper.fromPostgrest(error);
    } catch (_) {
      throw const PartnerException(
        message: 'Analitik sağlık durumu yüklenemedi.',
        kind: PartnerFailureKind.networkError,
      );
    }
  }

  Future<List<T>> _runList<T>({
    required String rpcName,
    required Map<String, dynamic> params,
    required T Function(Map<String, dynamic>) mapper,
    required String failureMessage,
  }) async {
    try {
      final result = await _resolvedClient.rpc(rpcName, params: params);
      final rows = parsePartnerRpcList(result);
      return rows.map(mapper).toList(growable: false);
    } on PartnerException {
      rethrow;
    } on FormatException catch (error) {
      throw PartnerErrorMapper.parseFailure(error.message);
    } on PostgrestException catch (error) {
      throw PartnerErrorMapper.fromPostgrest(error);
    } catch (_) {
      throw PartnerException(
        message: failureMessage,
        kind: PartnerFailureKind.networkError,
      );
    }
  }

  Future<T> _runMap<T>({
    required String rpcName,
    required Map<String, dynamic> params,
    required T Function(Map<String, dynamic>) mapper,
    required String failureMessage,
  }) async {
    try {
      final result = await _resolvedClient.rpc(rpcName, params: params);
      final map = parsePartnerRpcMap(result);
      return mapper(map);
    } on PartnerException {
      rethrow;
    } on FormatException catch (error) {
      throw PartnerErrorMapper.parseFailure(error.message);
    } on PostgrestException catch (error) {
      throw PartnerErrorMapper.fromPostgrest(error);
    } catch (_) {
      throw PartnerException(
        message: failureMessage,
        kind: PartnerFailureKind.networkError,
      );
    }
  }
}
