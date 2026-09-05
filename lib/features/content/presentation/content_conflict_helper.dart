import 'package:flutter/material.dart';

import '../../../l10n/admin_l10n.dart';
import '../data/content_errors.dart';

/// Handles optimistic concurrency conflicts: reloads fresh data and shows
/// the localized conflict message without auto-retrying the mutation.
Future<T?> handleContentConflict<T>({
  required BuildContext context,
  required ContentException error,
  required Future<T> Function() reloadFresh,
  required void Function(T fresh) onFreshLoaded,
}) async {
  if (!error.isConflict) {
    return null;
  }

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.contentConflictReloaded),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  final fresh = await reloadFresh();
  onFreshLoaded(fresh);
  return fresh;
}

void showContentErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

void showContentSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: const Color(0xFF35C46A)),
  );
}

Future<bool> confirmContentAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String? cancelLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF181818),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelLabel ?? context.l10n.dismiss),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE50914),
            ),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );

  return result ?? false;
}
