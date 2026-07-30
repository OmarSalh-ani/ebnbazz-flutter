import 'package:flutter/material.dart';

import '../../../core/platform/picked_student_photo.dart';
import '../models/public_registration_models.dart';
import '../utils/birthdate_helper.dart';

class RegistrationStudentFormState {
  RegistrationStudentFormState();

  final fullNameController = TextEditingController();
  final birthDayController = TextEditingController();
  final birthMonthController = TextEditingController();
  final birthYearController = TextEditingController();
  final ageController = TextEditingController();
  final learnController = TextEditingController();
  final addressController = TextEditingController();
  final healthDetailsController = TextEditingController();
  final learningDetailsController = TextEditingController();

  final fullNameFocusNode = FocusNode();
  final ageFocusNode = FocusNode();
  final learnFocusNode = FocusNode();
  final birthDayFocusNode = FocusNode();
  final birthMonthFocusNode = FocusNode();
  final birthYearFocusNode = FocusNode();
  final addressFocusNode = FocusNode();
  final healthDetailsFocusNode = FocusNode();
  final learningDetailsFocusNode = FocusNode();

  String activityId = '';
  String maritalStatus = 'متزوج / ة';
  bool hasHealthCondition = false;
  bool hasLearningDifficulties = false;
  PickedStudentPhoto? pickedPhoto;

  void dispose() {
    fullNameController.dispose();
    birthDayController.dispose();
    birthMonthController.dispose();
    birthYearController.dispose();
    ageController.dispose();
    learnController.dispose();
    addressController.dispose();
    healthDetailsController.dispose();
    learningDetailsController.dispose();
    fullNameFocusNode.dispose();
    ageFocusNode.dispose();
    learnFocusNode.dispose();
    birthDayFocusNode.dispose();
    birthMonthFocusNode.dispose();
    birthYearFocusNode.dispose();
    addressFocusNode.dispose();
    healthDetailsFocusNode.dispose();
    learningDetailsFocusNode.dispose();
  }

  RegistrationStudentEntry toEntry({
    required String mode,
    required bool showBirthdateDiv,
    required bool showAgeDiv,
  }) {
    return RegistrationStudentEntry(
      fullName: fullNameController.text.trim(),
      birthdate: showBirthdateDiv
          ? BirthdateHelper.buildBirthdateIso(
              birthDayController.text,
              birthMonthController.text,
              birthYearController.text,
            )
          : null,
      age: showAgeDiv ? int.tryParse(ageController.text) : null,
      learnCertificate: learnController.text.trim().isEmpty
          ? null
          : learnController.text.trim(),
      womanActivityTypeId: int.parse(activityId),
      address: addressController.text.trim(),
      maritalStatus: maritalStatus,
      hasHealthCondition: hasHealthCondition,
      healthDetails: hasHealthCondition
          ? healthDetailsController.text.trim()
          : null,
      hasLearningDifficulties: hasLearningDifficulties,
      learningDifficultiesDetails: hasLearningDifficulties
          ? learningDetailsController.text.trim()
          : null,
    );
  }
}
