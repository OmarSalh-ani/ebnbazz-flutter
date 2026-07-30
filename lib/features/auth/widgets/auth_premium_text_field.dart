import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:masged_parent_app/splash/splash_colors.dart';

class AuthPremiumTextField extends StatelessWidget {
  const AuthPremiumTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.label,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.obscureText = false,
    this.onToggleObscure,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.onFieldSubmitted,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final String label;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isFocused
                ? SplashColors.gold
                : SplashColors.whiteText.withValues(alpha: 0.62),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isFocused
                  ? SplashColors.gold.withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.12),
              width: isFocused ? 1.5 : 1.0,
            ),
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            obscureText: isPassword ? obscureText : false,
            keyboardType: keyboardType,
            validator: validator,
            textInputAction: textInputAction,
            onFieldSubmitted: onFieldSubmitted,
            maxLines: maxLines,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: AppFonts.cairo(
              color: SplashColors.whiteText,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.transparent,
              hintText: hint,
              hintStyle: AppFonts.cairo(
                color: SplashColors.whiteText.withValues(alpha: 0.28),
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              errorStyle: AppFonts.cairo(
                color: const Color(0xFFFFB4B4),
                fontSize: 12,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              prefixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscureText
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: isFocused
                            ? SplashColors.gold
                            : SplashColors.whiteText.withValues(alpha: 0.28),
                        size: 20,
                      ),
                      onPressed: onToggleObscure,
                    )
                  : null,
              suffixIcon: Padding(
                padding: const EdgeInsetsDirectional.only(end: 14),
                child: Icon(
                  icon,
                  color: isFocused
                      ? SplashColors.gold
                      : SplashColors.whiteText.withValues(alpha: 0.28),
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
