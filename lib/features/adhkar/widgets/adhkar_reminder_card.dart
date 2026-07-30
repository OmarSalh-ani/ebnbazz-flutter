import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:masged_parent_app/shared/router/app_routes.dart';

import '../providers/adhkar_progress_provider.dart';

class AdhkarReminderCard extends ConsumerWidget {
  const AdhkarReminderCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminder = ref.watch(adhkarReminderProvider);

    if (!reminder.showMorning && !reminder.showEvening) {
      return const SizedBox.shrink();
    }

    final isMorning = reminder.showMorning;
    final title = isMorning ? 'أذكار الصباح' : 'أذكار المساء';
    final subtitle = isMorning
        ? 'حان وقت أذكار الصباح — لا تنس ذكر الله'
        : 'حان وقت أذكار المساء — أحصن نفسك بذكر الله';
    final icon = isMorning ? Icons.wb_sunny_rounded : Icons.nightlight_round;
    final gradient = isMorning
        ? const [Color(0xFFFFE082), Color(0xFFFFB74D)]
        : const [Color(0xFFB39DDB), Color(0xFF7E57C2)];
    final groupId = isMorning ? 'morning' : 'evening';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(AppRoutes.adhkarGroupPath(groupId)),
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: gradient,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradient.last.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: AppFonts.cairo(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.92),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_left_rounded,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
