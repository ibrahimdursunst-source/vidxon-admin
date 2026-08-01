import 'package:flutter/material.dart';

import '../../admin_context/presentation/admin_context_scope.dart';

/// Returns false while [AdminContextScope] is loading or errored so content
/// mutations stay fail-closed until admin context is ready.
bool contentMutationsEnabled(BuildContext context) {
  final result = AdminContextScope.maybeOf(context);
  if (result == null) {
    return true;
  }

  return !result.isLoading && result.hasContext;
}
