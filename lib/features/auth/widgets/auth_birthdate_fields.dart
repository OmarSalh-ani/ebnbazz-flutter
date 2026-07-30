import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:masged_parent_app/splash/splash_colors.dart';

import '../utils/birthdate_helper.dart';

class AuthBirthdateFields extends StatelessWidget {
  const AuthBirthdateFields({
    super.key,
    required this.dayController,
    required this.monthController,
    required this.yearController,
    required this.dayFocusNode,
    required this.monthFocusNode,
    required this.yearFocusNode,
    required this.validator,
    this.onComplete,
  });

  final TextEditingController dayController;
  final TextEditingController monthController;
  final TextEditingController yearController;
  final FocusNode dayFocusNode;
  final FocusNode monthFocusNode;
  final FocusNode yearFocusNode;
  final String? Function(String?) validator;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (_) => validator(
        BirthdateHelper.buildBirthdateIso(
          dayController.text,
          monthController.text,
          yearController.text,
        ),
      ),
      builder: (field) {
        final hasError = field.hasError;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تاريخ الميلاد *',
              style: AppFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: SplashColors.whiteText.withValues(alpha: 0.62),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DatePartField(
                    label: 'اليوم',
                    controller: dayController,
                    focusNode: dayFocusNode,
                    maxLength: 2,
                    hint: '01',
                    hasError: hasError,
                    onChanged: (v) {
                      dayController.text =
                          BirthdateHelper.sanitizeDatePartInput(v, 2, 31);
                      field.didChange(dayController.text);
                    },
                    onBlur: () {
                      dayController.text = BirthdateHelper.padDatePartOnBlur(
                        dayController.text,
                        31,
                      );
                    },
                    onSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(monthFocusNode),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DatePartField(
                    label: 'الشهر',
                    controller: monthController,
                    focusNode: monthFocusNode,
                    maxLength: 2,
                    hint: '01',
                    hasError: hasError,
                    onChanged: (v) {
                      monthController.text =
                          BirthdateHelper.sanitizeDatePartInput(v, 2, 12);
                      field.didChange(monthController.text);
                    },
                    onBlur: () {
                      monthController.text = BirthdateHelper.padDatePartOnBlur(
                        monthController.text,
                        12,
                      );
                    },
                    onSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(yearFocusNode),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _DatePartField(
                    label: 'السنة',
                    controller: yearController,
                    focusNode: yearFocusNode,
                    maxLength: 4,
                    hint: '2010',
                    hasError: hasError,
                    onChanged: (v) {
                      yearController.text = v.replaceAll(RegExp(r'\D'), '');
                      if (yearController.text.length > 4) {
                        yearController.text =
                            yearController.text.substring(0, 4);
                      }
                      field.didChange(yearController.text);
                    },
                    onSubmitted: (_) => onComplete?.call(),
                  ),
                ),
              ],
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

class _DatePartField extends StatelessWidget {
  const _DatePartField({
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.maxLength,
    required this.hint,
    required this.hasError,
    required this.onChanged,
    this.onBlur,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final int maxLength;
  final String hint;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final VoidCallback? onBlur;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppFonts.cairo(
            fontSize: 11,
            color: SplashColors.whiteText.withValues(alpha: 0.45),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError
                  ? const Color(0xFFFFB4B4).withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: TextInputType.number,
            maxLength: maxLength,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: AppFonts.cairo(color: SplashColors.whiteText, fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.transparent,
              counterText: '',
              hintText: hint,
              hintStyle: AppFonts.cairo(
                color: SplashColors.whiteText.withValues(alpha: 0.28),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: onChanged,
            onFieldSubmitted: onSubmitted,
            onEditingComplete: onBlur,
          ),
        ),
      ],
    );
  }
}
