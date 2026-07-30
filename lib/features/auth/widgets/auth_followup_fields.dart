import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:masged_parent_app/core/utils/validators.dart';
import 'package:masged_parent_app/splash/splash_colors.dart';

import '../widgets/auth_premium_text_field.dart';

class AuthFollowupFields extends StatelessWidget {
  const AuthFollowupFields({
    super.key,
    required this.addressController,
    required this.addressFocusNode,
    required this.isAddressFocused,
    required this.maritalStatus,
    required this.onMaritalStatusChanged,
    required this.hasHealthCondition,
    required this.onHealthChanged,
    required this.healthDetailsController,
    required this.healthDetailsFocusNode,
    required this.isHealthDetailsFocused,
    required this.hasLearningDifficulties,
    required this.onLearningChanged,
    required this.learningDetailsController,
    required this.learningDetailsFocusNode,
    required this.isLearningDetailsFocused,
  });

  final TextEditingController addressController;
  final FocusNode addressFocusNode;
  final bool isAddressFocused;
  final String maritalStatus;
  final ValueChanged<String> onMaritalStatusChanged;
  final bool hasHealthCondition;
  final ValueChanged<bool> onHealthChanged;
  final TextEditingController healthDetailsController;
  final FocusNode healthDetailsFocusNode;
  final bool isHealthDetailsFocused;
  final bool hasLearningDifficulties;
  final ValueChanged<bool> onLearningChanged;
  final TextEditingController learningDetailsController;
  final FocusNode learningDetailsFocusNode;
  final bool isLearningDetailsFocused;

  static const maritalOptions = [
    'متزوج / ة',
    'متوفي /ة',
    'مطلق / ة',
    'أعزب',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthPremiumTextField(
          controller: addressController,
          focusNode: addressFocusNode,
          isFocused: isAddressFocused,
          label: 'عنوان السكن *',
          hint: 'أدخل عنوان السكن',
          icon: Icons.location_on_outlined,
          validator: Validators.validateAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 20),
        Text(
          'الحالة الاجتماعية لولي الأمر *',
          style: AppFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: SplashColors.whiteText.withValues(alpha: 0.62),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              initialValue: maritalOptions.contains(maritalStatus)
                  ? maritalStatus
                  : maritalOptions.first,
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              ),
              dropdownColor: SplashColors.background,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: SplashColors.whiteText.withValues(alpha: 0.5),
              ),
              items: maritalOptions
                  .map(
                    (o) => DropdownMenuItem(
                      value: o,
                      child: Text(
                        o,
                        style: AppFonts.cairo(color: SplashColors.whiteText),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) onMaritalStatusChanged(v);
              },
              validator: Validators.validateMaritalStatus,
            ),
          ),
        ),
        const SizedBox(height: 20),
        _AuthSwitchTile(
          title: 'هل يعاني الطالب من أي حالة صحية أو إعاقة؟',
          value: hasHealthCondition,
          onChanged: onHealthChanged,
        ),
        if (hasHealthCondition) ...[
          const SizedBox(height: 12),
          AuthPremiumTextField(
            controller: healthDetailsController,
            focusNode: healthDetailsFocusNode,
            isFocused: isHealthDetailsFocused,
            label: 'يرجى التوضيح',
            hint: 'تفاصيل الحالة الصحية',
            icon: Icons.medical_information_outlined,
            maxLines: 3,
            validator: (v) =>
                Validators.validateOptionalDetails(v, hasHealthCondition),
          ),
        ],
        const SizedBox(height: 16),
        _AuthSwitchTile(
          title: 'هل يعاني الطالب من صعوبات تعليمية أو سلوكية؟',
          value: hasLearningDifficulties,
          onChanged: onLearningChanged,
        ),
        if (hasLearningDifficulties) ...[
          const SizedBox(height: 12),
          AuthPremiumTextField(
            controller: learningDetailsController,
            focusNode: learningDetailsFocusNode,
            isFocused: isLearningDetailsFocused,
            label: 'يرجى التوضيح',
            hint: 'تفاصيل الصعوبات التعليمية',
            icon: Icons.psychology_outlined,
            maxLines: 3,
            validator: (v) =>
                Validators.validateOptionalDetails(v, hasLearningDifficulties),
          ),
        ],
      ],
    );
  }
}

class _AuthSwitchTile extends StatelessWidget {
  const _AuthSwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppFonts.cairo(
                fontSize: 13,
                color: SplashColors.whiteText.withValues(alpha: 0.78),
                height: 1.4,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: SplashColors.gold,
            activeTrackColor: SplashColors.gold.withValues(alpha: 0.35),
          ),
        ],
      ),
    );
  }
}
