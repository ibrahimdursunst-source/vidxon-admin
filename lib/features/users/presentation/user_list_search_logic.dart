import '../../admin_context/domain/admin_role.dart';
import '../domain/admin_user_summary.dart';

bool shouldSkipDebouncedUserSearch({
  required String query,
  required String activeQuery,
  required bool isLoading,
  required bool isLoadingMore,
}) {
  return query == activeQuery && !isLoading && !isLoadingMore;
}

bool shouldSkipDuplicateInFlightSearch({
  required String query,
  required String? inFlightQuery,
  required bool isLoading,
  required bool reset,
}) {
  return reset && isLoading && inFlightQuery == query;
}

bool isAdminAddSearchQueryReady(String query) {
  return query.trim().isNotEmpty;
}

bool canAddUserAsAdmin(AdminUserSummary user) {
  return user.adminRole == null;
}

String adminRolePermissionDescription(AdminRole role) {
  return switch (role) {
    AdminRole.admin =>
      'Admin; kullanıcıları ve cüzdan işlemlerini yönetebilir, '
          'işlem kayıtlarını görüntüleyebilir.',
    AdminRole.superAdmin =>
      'Super Admin; yönetici rollerini değiştirebilir, admin erişimini '
          'kaldırabilir ve tüm işlem kayıtlarını görüntüleyebilir.',
  };
}

String buildAdminAddSuccessMessage({
  required String displayName,
  required AdminRole role,
}) {
  return switch (role) {
    AdminRole.admin => '$displayName Admin olarak eklendi.',
    AdminRole.superAdmin => '$displayName Super Admin olarak eklendi.',
  };
}
