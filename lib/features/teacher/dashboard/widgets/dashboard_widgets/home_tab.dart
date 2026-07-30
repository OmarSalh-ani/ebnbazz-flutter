import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:masged_parent_app/shared/widgets/mosque_section_header.dart';
import 'package:masged_parent_app/shared/widgets/quick_services.dart';
import '../../models/dashboard_models.dart';
import '../../providers/dashboard_providers.dart';
import '../../providers/teacher_attendance_providers.dart';
import '../../../../video_call/providers/video_call_providers.dart';
import '../../../../video_call/widgets/ongoing_meeting_card.dart';
import '../teacher_attendance_container.dart';
import 'identity_header.dart';
import 'stats_section.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({
    super.key,
    required this.data,
  });

  final DashboardPageData? data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(mosqueProximityProvider);
        ref.invalidate(videoCallMeetingsProvider);
        await ref.read(dashboardPageProvider.notifier).refresh();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const TeacherOngoingMeetingCard(),
            if (data != null) ...[
              TeacherAttendanceContainer(data: data!),
              const SizedBox(height: 24),
              StatsSection(stats: data!.statistics),
              const SizedBox(height: 24),
              MosqueSectionHeader('خدمات سريعة'),
              const SizedBox(height: 12),
              QuickServicesRowNeutral(),
              const SizedBox(height: 24),
            ] else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
