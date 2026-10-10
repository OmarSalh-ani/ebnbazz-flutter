import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/router/app_router.dart';
import '../../../shared/router/app_routes.dart';
import '../providers/students_provider.dart';

Future<void> openStudentPlanFromPushNotification(
  WidgetRef ref, {
  required int studentId,
}) async {
  final context = await _waitForNavigator(ref);
  if (context == null || !context.mounted) return;

  try {
    final child = await ref
        .read(studentsApiServiceProvider)
        .getStudentProfile('$studentId');
    if (!context.mounted) return;
    context.push(
      '${AppRoutes.childProfilePath(child.id)}?focus=plan',
      extra: child,
    );
  } catch (_) {}
}

Future<BuildContext?> _waitForNavigator(WidgetRef ref) async {
  for (var attempt = 0; attempt < 10; attempt++) {
    final context =
        ref.read(appRouterProvider).routerDelegate.navigatorKey.currentContext;
    if (context != null && context.mounted) return context;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  return null;
}
