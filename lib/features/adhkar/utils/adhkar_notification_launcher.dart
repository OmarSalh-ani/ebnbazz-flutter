import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/router/app_router.dart';
import '../../../shared/router/app_routes.dart';

Future<void> openAdhkarFromPushNotification(
  WidgetRef ref,
  String groupId,
) async {
  final context =
      ref.read(appRouterProvider).routerDelegate.navigatorKey.currentContext;
  if (context == null || !context.mounted) return;
  context.push(AppRoutes.adhkarGroupPath(groupId));
}
