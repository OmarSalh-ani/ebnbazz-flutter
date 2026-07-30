import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../notifications/models/parent_notification_item.dart';
import '../../notifications/providers/parent_notifications_provider.dart';
import '../models/video_call_models.dart';
import 'video_call_providers.dart';

final parentActiveMeetingsProvider =
    FutureProvider.autoDispose<List<ParentNotificationItem>>((ref) async {
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated) return const [];

  final items = await ref.watch(parentNotificationsProvider.future);
  return items.where((n) => n.kind == 'meet' && n.canJoin).toList();
});

final teacherActiveMeetingsProvider =
    FutureProvider.autoDispose<List<VideoCallListRow>>((ref) async {
  final meetings = await ref.watch(videoCallMeetingsProvider.future);
  return meetings.where((m) => m.isActive).toList();
});
