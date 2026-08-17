import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../models/child_model.dart';

/// Parent Quran screen — assignment from teacher plans is no longer available.
class QuranScreen extends StatelessWidget {
  final ChildModel child;

  const QuranScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'تسميع القرآن',
          style: AppFonts.cairo(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.menu_book_rounded,
                size: 56,
                color: AppColors.primary.withValues(alpha: 0.7),
              ).animate().fadeIn().scale(delay: 100.ms),
              const SizedBox(height: 16),
              Text(
                child.name,
                style: AppFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'لا توجد خطة حفظ أو مراجعة متاحة حالياً',
                style: AppFonts.cairo(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
