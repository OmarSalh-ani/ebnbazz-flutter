import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/parent_followup_model.dart';
import '../services/parent_followup_api_service.dart';

final parentFollowupApiServiceProvider =
    Provider((ref) => ParentFollowupApiService());

final parentFollowupProvider = FutureProvider<ParentFollowupModel>((ref) async {
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated) {
    return const ParentFollowupModel();
  }
  return ref.read(parentFollowupApiServiceProvider).getFollowup();
});
