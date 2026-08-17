import 'package:flutter/material.dart';

extension AppThemeColors on BuildContext {
  Color get appPrimary => Theme.of(this).colorScheme.primary;

  Color get appPrimaryLight =>
      Theme.of(this).colorScheme.primaryContainer;

  Color get appPrimaryMuted =>
      appPrimary.withValues(alpha: 0.12);
}
