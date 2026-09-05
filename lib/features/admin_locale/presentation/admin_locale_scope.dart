import 'package:flutter/material.dart';

import '../application/admin_locale_controller.dart';

class AdminLocaleScope extends InheritedNotifier<AdminLocaleController> {
  const AdminLocaleScope({
    required AdminLocaleController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static AdminLocaleController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AdminLocaleScope>();
    assert(scope != null, 'AdminLocaleScope not found');
    return scope!.notifier!;
  }

  static AdminLocaleController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AdminLocaleScope>()
        ?.notifier;
  }
}
