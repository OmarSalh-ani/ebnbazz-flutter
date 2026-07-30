import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/utils/validators.dart';

import 'auth_country_phone_field.dart';

class AuthPhoneField extends StatelessWidget {
  const AuthPhoneField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    this.onFieldSubmitted,
    this.onCountryChanged,
    this.countryIso = 'KW',
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onCountryChanged;
  final String countryIso;

  @override
  Widget build(BuildContext context) {
    return AuthCountryPhoneField(
      label: 'رقم الجوال',
      countryIso: countryIso,
      phoneController: controller,
      focusNode: focusNode,
      isFocused: isFocused,
      onCountryChanged: onCountryChanged ?? (_) {},
      onFieldSubmitted: onFieldSubmitted,
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return 'يرجى إدخال رقم الجوال';
        }
        return Validators.validateInternationalPhone(v, countryIso);
      },
    );
  }
}
