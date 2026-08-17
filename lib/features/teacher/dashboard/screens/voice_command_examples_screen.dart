import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';

import 'package:masged_parent_app/core/theme/app_colors.dart';
import 'package:masged_parent_app/core/theme/app_theme_extensions.dart';
import 'package:masged_parent_app/teacher_core/services/voice_command_service.dart';
import '../../auth/providers/auth_providers.dart';

class VoiceCommandExamplesScreen extends ConsumerWidget {
  const VoiceCommandExamplesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMrkz = ref.watch(teacherIsMrkzProvider);
    final examples = VoiceCommandService.commandExamples
        .where((example) => !isMrkz || example.category != 'إنشاء خطة')
        .toList();

    final groupedExamples = <String, List<VoiceCommandExample>>{};
    for (final example in examples) {
      groupedExamples.putIfAbsent(example.category, () => []).add(example);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'أمثلة الأوامر الصوتية',
          style: AppFonts.cairo(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.appPrimaryLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.appPrimary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: context.appPrimary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isMrkz
                        ? 'في وضع المركز يمكنك استخدام أوامر الحضور والانصراف فقط.'
                        : 'يمكنك نطق أي من الأمثلة التالية. تحدث ثم اضغط إيقاف لتحليل الأمر، وبعدها راجع النتيجة وأكّد التنفيذ.',
                    style: AppFonts.cairo(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...groupedExamples.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: AppFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.appPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...entry.value.map(
                    (example) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ExampleCard(example: example),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExampleCard extends StatelessWidget {
  const _ExampleCard({required this.example});

  final VoiceCommandExample example;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            example.phrase,
            style: AppFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            example.description,
            style: AppFonts.cairo(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
