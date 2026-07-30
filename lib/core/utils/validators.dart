class Validators {
  Validators._();

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال البريد الإلكتروني';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'البريد الإلكتروني غير صالح';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال رقم الجوال';
    }
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length != 8) {
      return 'رقم الجوال يجب أن يتكون من 8 أرقام';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال كلمة المرور';
    }
    if (value.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى تأكيد كلمة المرور';
    }
    if (value != password) {
      return 'كلمة المرور غير متطابقة';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال الاسم';
    }
    if (value.trim().length < 3) {
      return 'الاسم يجب أن يكون 3 أحرف على الأقل';
    }
    return null;
  }

  static String digitsOnly(String? value) =>
      value?.replaceAll(RegExp(r'\D'), '') ?? '';

  static int? phoneMaxLength(String countryIso) =>
      countryIso.toUpperCase() == 'KW' ? 8 : 15;

  static String? validateInternationalPhone(String? value, String countryIso) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال رقم الجوال';
    }
    final digits = digitsOnly(value);
    if (countryIso.toUpperCase() == 'KW') {
      if (digits.length != 8) {
        return 'يجب أن يكون رقم الهاتف 8 أرقام (رقم كويتي صحيح)';
      }
      return null;
    }
    if (digits.length < 7 || digits.length > 15) {
      return 'أدخل رقم الجوال بدون رمز الدولة (7–15 رقماً)';
    }
    return null;
  }

  static String? validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال العمر';
    }
    final parsed = int.tryParse(value);
    if (parsed == null || parsed < 5) {
      return 'يجب أن لا يقل العمر عن 5 سنوات';
    }
    return null;
  }

  static String? validateActivity(String? activityId) {
    if (activityId == null || activityId.isEmpty) {
      return 'يرجى اختيار نوع النشاط';
    }
    return null;
  }

  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال العنوان';
    }
    return null;
  }

  static String? validateMaritalStatus(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى اختيار الحالة الاجتماعية';
    }
    return null;
  }

  static String? validateOptionalDetails(String? value, bool required) {
    if (!required) return null;
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال التفاصيل';
    }
    return null;
  }

  static String? validateBirthdateIso(String? iso) {
    if (iso == null || iso.isEmpty) {
      return 'يرجى إدخال تاريخ ميلاد صحيح';
    }
    return null;
  }

  static String? validateOtp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال رمز التحقق';
    }
    if (value.length != 6) {
      return 'رمز التحقق يتكون من 6 أرقام';
    }
    return null;
  }
}
