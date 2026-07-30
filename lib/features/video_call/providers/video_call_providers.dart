import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../teacher/auth/providers/auth_providers.dart';
import '../data/parent_video_call_api.dart';
import '../data/video_call_api.dart';
import '../models/video_call_models.dart';

final videoCallApiProvider = Provider<VideoCallApi>((ref) {
  return VideoCallApi(ref.watch(apiClientProvider));
});

final parentVideoCallApiProvider = Provider<ParentVideoCallApi>((ref) {
  return ParentVideoCallApi();
});

final videoCallCatalogProvider =
    FutureProvider.autoDispose<VideoCallCatalog>((ref) async {
  return ref.watch(videoCallApiProvider).fetchCatalog();
});

final videoCallMeetingsProvider =
    FutureProvider.autoDispose<List<VideoCallListRow>>((ref) async {
  return ref.watch(videoCallApiProvider).listMeetings();
});
