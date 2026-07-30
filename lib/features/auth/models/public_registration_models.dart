class ApiResponseDto<T> {
  final bool success;
  final String message;
  final T? data;
  final List<String> errors;

  const ApiResponseDto({
    required this.success,
    required this.message,
    this.data,
    this.errors = const [],
  });

  factory ApiResponseDto.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final rawData = json['data'];
    return ApiResponseDto(
      success: json['success'] as bool? ?? false,
      message: json['message']?.toString() ?? '',
      data: rawData is Map<String, dynamic> ? fromJsonT(rawData) : null,
      errors: (json['errors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

class PublicWomanActivityOption {
  final int id;
  final String name;

  const PublicWomanActivityOption({required this.id, required this.name});

  factory PublicWomanActivityOption.fromJson(Map<String, dynamic> json) {
    return PublicWomanActivityOption(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }
}

class PublicRegistrationFormLabels {
  final String fullNameLabel;
  final String parentPhone1Label;
  final String learnCertificateLabel;
  final bool showLearnDiv;
  final bool showBirthdateDiv;
  final bool showAgeDiv;
  final bool showPhone2Div;
  final bool showActivitiesSection;
  final bool showActivitiesNav;

  const PublicRegistrationFormLabels({
    required this.fullNameLabel,
    required this.parentPhone1Label,
    required this.learnCertificateLabel,
    required this.showLearnDiv,
    required this.showBirthdateDiv,
    required this.showAgeDiv,
    required this.showPhone2Div,
    required this.showActivitiesSection,
    required this.showActivitiesNav,
  });

  factory PublicRegistrationFormLabels.fromJson(Map<String, dynamic> json) {
    return PublicRegistrationFormLabels(
      fullNameLabel:
          json['fullNameLabel']?.toString() ?? 'الاسم الرباعي للطالب *',
      parentPhone1Label:
          json['parentPhone1Label']?.toString() ?? 'رقم هاتف ولي الأمر 1 *',
      learnCertificateLabel:
          json['learnCertificateLabel']?.toString() ?? 'المؤهل العلمي',
      showLearnDiv: json['showLearnDiv'] as bool? ?? false,
      showBirthdateDiv: json['showBirthdateDiv'] as bool? ?? true,
      showAgeDiv: json['showAgeDiv'] as bool? ?? false,
      showPhone2Div: json['showPhone2Div'] as bool? ?? true,
      showActivitiesSection: json['showActivitiesSection'] as bool? ?? true,
      showActivitiesNav: json['showActivitiesNav'] as bool? ?? true,
    );
  }
}

class PublicRegistrationConfig {
  final String mode;
  final bool registrationEnabled;
  final PublicRegistrationFormLabels labels;
  final List<PublicWomanActivityOption> womanActivities;

  const PublicRegistrationConfig({
    required this.mode,
    required this.registrationEnabled,
    required this.labels,
    required this.womanActivities,
  });

  factory PublicRegistrationConfig.fromJson(Map<String, dynamic> json) {
    final activities = (json['womanActivities'] as List<dynamic>? ?? [])
        .map((e) => PublicWomanActivityOption.fromJson(
              e as Map<String, dynamic>,
            ))
        .toList();

    return PublicRegistrationConfig(
      mode: json['mode']?.toString() ?? 'default',
      registrationEnabled: json['registrationEnabled'] as bool? ?? false,
      labels: PublicRegistrationFormLabels.fromJson(
        json['labels'] as Map<String, dynamic>? ?? {},
      ),
      womanActivities: activities,
    );
  }
}

class CountryDialEntry {
  final String name;
  final String dialCode;
  final String code;

  const CountryDialEntry({
    required this.name,
    required this.dialCode,
    required this.code,
  });

  factory CountryDialEntry.fromJson(Map<String, dynamic> json) {
    return CountryDialEntry(
      name: json['name']?.toString() ?? '',
      dialCode: json['dial_code']?.toString() ?? json['dialCode']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
    );
  }
}

class RegistrationStudentEntry {
  final String fullName;
  final String? birthdate;
  final int? age;
  final String? learnCertificate;
  final int womanActivityTypeId;
  final String address;
  final String maritalStatus;
  final bool hasHealthCondition;
  final String? healthDetails;
  final bool hasLearningDifficulties;
  final String? learningDifficultiesDetails;

  const RegistrationStudentEntry({
    required this.fullName,
    this.birthdate,
    this.age,
    this.learnCertificate,
    required this.womanActivityTypeId,
    required this.address,
    required this.maritalStatus,
    required this.hasHealthCondition,
    this.healthDetails,
    required this.hasLearningDifficulties,
    this.learningDifficultiesDetails,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      if (birthdate != null) 'birthdate': birthdate,
      if (age != null) 'age': age,
      if (learnCertificate != null && learnCertificate!.isNotEmpty)
        'learnCertificate': learnCertificate,
      'womanActivityTypeId': womanActivityTypeId,
      'address': address,
      'maritalStatus': maritalStatus,
      'hasHealthCondition': hasHealthCondition,
      if (healthDetails != null && healthDetails!.isNotEmpty)
        'healthDetails': healthDetails,
      'hasLearningDifficulties': hasLearningDifficulties,
      if (learningDifficultiesDetails != null &&
          learningDifficultiesDetails!.isNotEmpty)
        'learningDifficultiesDetails': learningDifficultiesDetails,
    };
  }
}

class SubmitStudentRegistrationPayload {
  final String mode;
  final String parentPhoneCountryIso;
  final String parentPhone1;
  final String? parentPhone2;
  final String? parentPhone2CountryIso;
  final String password;
  final String? fatherName;
  final List<RegistrationStudentEntry> students;

  const SubmitStudentRegistrationPayload({
    this.mode = 'default',
    required this.parentPhoneCountryIso,
    required this.parentPhone1,
    this.parentPhone2,
    this.parentPhone2CountryIso,
    required this.password,
    this.fatherName,
    required this.students,
  });

  Map<String, dynamic> toJson() {
    return {
      'mode': mode,
      'parentPhoneCountryIso': parentPhoneCountryIso,
      'parentPhone1': parentPhone1,
      if (parentPhone2 != null && parentPhone2!.isNotEmpty) 'parentPhone2': parentPhone2,
      if (parentPhone2CountryIso != null && parentPhone2CountryIso!.isNotEmpty)
        'parentPhone2CountryIso': parentPhone2CountryIso,
      'password': password,
      if (fatherName != null && fatherName!.isNotEmpty) 'fatherName': fatherName,
      'students': students.map((s) => s.toJson()).toList(),
    };
  }
}

class StudentRegistrationResult {
  final String token;
  final String parentId;
  final String fatherName;
  final String phone;
  final List<String> studentIds;

  const StudentRegistrationResult({
    required this.token,
    required this.parentId,
    required this.fatherName,
    required this.phone,
    required this.studentIds,
  });
}
