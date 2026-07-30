import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';

import 'package:masged_parent_app/core/theme/app_colors.dart';
import 'package:masged_parent_app/teacher_core/network/api_exception.dart';

class DashboardErrorState extends StatelessWidget {
  const DashboardErrorState({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = error is ApiException
        ? (error as ApiException).message
        : 'تعذر تحميل بيانات اللوحة';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppFonts.cairo(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: Text('إعادة المحاولة', style: AppFonts.cairo()),
            ),
          ],
        ),
      ),
    );
  }
}
