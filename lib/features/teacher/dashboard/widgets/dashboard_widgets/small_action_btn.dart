import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:masged_parent_app/core/theme/app_theme_extensions.dart';

class SmallActionBtn extends StatelessWidget {
  const SmallActionBtn({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: context.appPrimaryMuted,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: context.appPrimary),
            const SizedBox(width: 4),
            Text(
              title,
              style: AppFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: context.appPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
