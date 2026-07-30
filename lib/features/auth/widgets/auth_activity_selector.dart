import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:masged_parent_app/splash/splash_colors.dart';

import '../models/public_registration_models.dart';

class AuthActivitySelector extends StatelessWidget {
  const AuthActivitySelector({
    super.key,
    required this.activities,
    required this.selectedId,
    required this.onSelected,
    this.validator,
  });

  final List<PublicWomanActivityOption> activities;
  final String selectedId;
  final ValueChanged<String> onSelected;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: selectedId,
      validator: validator,
      builder: (field) {
        final hasError = field.hasError;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'نوع النشاط *',
              style: AppFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: SplashColors.whiteText.withValues(alpha: 0.62),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: activities.map((activity) {
                final id = activity.id.toString();
                final selected = selectedId == id;
                return GestureDetector(
                  onTap: () {
                    onSelected(id);
                    field.didChange(id);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? SplashColors.gold.withValues(alpha: 0.18)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasError && !selected
                            ? const Color(0xFFFFB4B4).withValues(alpha: 0.5)
                            : selected
                                ? SplashColors.gold.withValues(alpha: 0.65)
                                : Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Text(
                      activity.name,
                      style: AppFonts.cairo(
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected
                            ? SplashColors.gold
                            : SplashColors.whiteText.withValues(alpha: 0.78),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (hasError) ...[
              const SizedBox(height: 6),
              Text(
                field.errorText ?? '',
                style: AppFonts.cairo(
                  color: const Color(0xFFFFB4B4),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
