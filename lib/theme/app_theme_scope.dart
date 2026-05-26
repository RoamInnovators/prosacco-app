import 'package:flutter/material.dart';

import 'theme_controller.dart';

class AppThemeScope extends InheritedNotifier<ThemeController> {
  const AppThemeScope({
    super.key,
    required ThemeController super.notifier,
    required super.child,
  });

  static ThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppThemeScope>();
    assert(scope != null, 'AppThemeScope not found');
    return scope!.notifier!;
  }
}
