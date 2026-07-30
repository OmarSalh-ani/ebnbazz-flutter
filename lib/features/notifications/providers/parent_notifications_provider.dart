import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/parent_notification_item.dart';
import '../services/parent_notifications_api_service.dart';

final parentNotificationsApiProvider =
    Provider((_) => ParentNotificationsApiService());

final parentNotificationsProvider =
    FutureProvider<List<ParentNotificationItem>>((ref) async {
  return ref.watch(parentNotificationsApiProvider).fetchNotifications();
});
