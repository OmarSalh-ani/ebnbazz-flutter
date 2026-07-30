import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/schedule_slot_model.dart';
import '../services/parent_schedule_api_service.dart';

final parentScheduleApiProvider = Provider((_) => ParentScheduleApiService());

final parentScheduleProvider =
    FutureProvider<List<ScheduleSlotModel>>((ref) async {
  return ref.watch(parentScheduleApiProvider).fetchSchedule();
});
