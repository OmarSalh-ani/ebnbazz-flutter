import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

/// Opens the hosted privacy policy URL required by Google Play.
Future<void> openPrivacyPolicy() async {
  final uri = Uri.tryParse(AppConstants.privacyPolicyUrl);
  if (uri == null || !AppConstants.hasPrivacyPolicyUrl) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

class PrivacyPolicyLink extends StatelessWidget {
  const PrivacyPolicyLink({
    super.key,
    this.style,
    this.textAlign,
    this.compact = false,
  });

  final TextStyle? style;
  final TextAlign? textAlign;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!AppConstants.hasPrivacyPolicyUrl) {
      return const SizedBox.shrink();
    }

    final linkStyle = (style ?? AppFonts.cairo(fontSize: 13)).copyWith(
      color: AppColors.primary,
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.w600,
    );

    if (compact) {
      return TextButton(
        onPressed: openPrivacyPolicy,
        child: Text('سياسة الخصوصية', style: linkStyle),
      );
    }

    return Text.rich(
      textAlign: textAlign ?? TextAlign.center,
      TextSpan(
        style: style ??
            AppFonts.cairo(
              fontSize: 13,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
        children: [
          const TextSpan(text: 'بمتابعة استخدام التطبيق، فإنك توافق على '),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: openPrivacyPolicy,
              child: Text('سياسة الخصوصية', style: linkStyle),
            ),
          ),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }
}
