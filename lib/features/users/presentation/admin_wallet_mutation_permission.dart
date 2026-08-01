import '../../admin_context/presentation/admin_context_scope.dart';

bool canMutateAdminWallet({
  required AdminContextLoadResult? contextResult,
  required bool walletActionsAllowed,
}) {
  if (contextResult == null ||
      contextResult.isLoading ||
      contextResult.errorMessage != null ||
      !contextResult.hasContext) {
    return false;
  }

  return contextResult.isSuperAdmin && walletActionsAllowed;
}

String? adminWalletMutationRestrictionMessage({
  required AdminContextLoadResult? contextResult,
  required bool walletActionsAllowed,
}) {
  if (contextResult == null ||
      contextResult.isLoading ||
      contextResult.errorMessage != null) {
    return null;
  }

  if (!walletActionsAllowed) {
    return 'Admin hesaplarında manuel jeton işlemleri yapılamaz.';
  }

  if (!contextResult.isSuperAdmin) {
    return 'Jeton işlemleri yalnızca Super Admin tarafından yapılabilir.';
  }

  return null;
}
