import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:masged_parent_app/core/utils/validators.dart';
import 'package:masged_parent_app/splash/splash_colors.dart';

class AuthCountryPhoneField extends StatefulWidget {
  const AuthCountryPhoneField({
    super.key,
    required this.label,
    required this.countryIso,
    required this.phoneController,
    required this.focusNode,
    required this.isFocused,
    required this.onCountryChanged,
    this.validator,
    this.onFieldSubmitted,
    this.isOptional = false,
    this.hintText = '51234567',
  });

  final String label;
  final String countryIso;
  final TextEditingController phoneController;
  final FocusNode focusNode;
  final bool isFocused;
  final ValueChanged<String> onCountryChanged;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final bool isOptional;
  final String hintText;

  @override
  State<AuthCountryPhoneField> createState() => _AuthCountryPhoneFieldState();
}

class _AuthCountryPhoneFieldState extends State<AuthCountryPhoneField> {
  late PhoneNumber _initialValue;

  @override
  void initState() {
    super.initState();
    _initialValue = PhoneNumber(isoCode: widget.countryIso);
  }

  @override
  void didUpdateWidget(AuthCountryPhoneField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.countryIso != widget.countryIso) {
      _initialValue = PhoneNumber(isoCode: widget.countryIso);
    }
  }

  @override
  Widget build(BuildContext context) {
    final labelColor = widget.isFocused
        ? SplashColors.gold
        : SplashColors.whiteText.withValues(alpha: 0.62);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isFocused
                  ? SplashColors.gold.withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.12),
              width: widget.isFocused ? 1.5 : 1.0,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme:
                  Theme.of(context).inputDecorationTheme.copyWith(
                        filled: true,
                        fillColor: Colors.transparent,
                      ),
            ),
            child: InternationalPhoneNumberInput(
            key: ValueKey('phone-${widget.countryIso}-${widget.isOptional}'),
            focusNode: widget.focusNode,
            textFieldController: widget.phoneController,
            initialValue: _initialValue,
            formatInput: false,
            ignoreBlank: widget.isOptional,
            locale: 'ar',
            textAlign: TextAlign.right,
            keyboardType: TextInputType.phone,
            keyboardAction: TextInputAction.next,
            onFieldSubmitted: widget.onFieldSubmitted,
            selectorConfig: SelectorConfig(
              selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
              setSelectorButtonAsPrefixIcon: true,
              useEmoji: true,
              leadingPadding: 12,
              trailingSpace: false,
            ),
            countries: const ['KW', 'SA', 'AE', 'BH', 'OM', 'QA', 'EG', 'JO'],
            textStyle: AppFonts.cairo(
              color: SplashColors.whiteText,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            selectorTextStyle: AppFonts.cairo(
              color: SplashColors.whiteText.withValues(alpha: 0.88),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            searchBoxDecoration: InputDecoration(
              hintText: 'ابحث عن الدولة',
              hintStyle: AppFonts.cairo(
                color: SplashColors.whiteText.withValues(alpha: 0.45),
              ),
              prefixIcon: Icon(
                Icons.search,
                color: SplashColors.whiteText.withValues(alpha: 0.45),
              ),
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            inputDecoration: InputDecoration(
              filled: true,
              fillColor: Colors.transparent,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              hintText: widget.hintText,
              hintStyle: AppFonts.cairo(
                color: SplashColors.whiteText.withValues(alpha: 0.28),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 14,
              ),
              errorStyle: AppFonts.cairo(
                color: const Color(0xFFFFB4B4),
                fontSize: 12,
              ),
            ),
            onInputChanged: (PhoneNumber number) {
              final iso = number.isoCode ?? widget.countryIso;
              if (iso != widget.countryIso) {
                widget.onCountryChanged(iso);
              }
            },
            validator: (value) {
              final digits = Validators.digitsOnly(value);
              if (widget.isOptional && digits.isEmpty) return null;
              if (widget.validator != null) {
                return widget.validator!(digits.isEmpty ? value : digits);
              }
              return Validators.validateInternationalPhone(
                digits.isEmpty ? value : digits,
                widget.countryIso,
              );
            },
            autoValidateMode: AutovalidateMode.disabled,
            ),
          ),
        ),
      ],
    );
  }
}
