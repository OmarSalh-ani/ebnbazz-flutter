import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:masged_parent_app/core/utils/validators.dart';
import 'package:masged_parent_app/splash/splash_colors.dart';

import '../models/public_registration_models.dart';
import '../models/registration_student_form_state.dart';
import 'auth_activity_selector.dart';
import 'auth_birthdate_fields.dart';
import 'auth_followup_fields.dart';
import 'auth_premium_text_field.dart';
import 'auth_student_photo_picker.dart';

class RegistrationStudentCard extends StatefulWidget {
  const RegistrationStudentCard({
    super.key,
    required this.index,
    required this.state,
    required this.config,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
    this.embeddedInTabs = false,
  });

  final int index;
  final RegistrationStudentFormState state;
  final PublicRegistrationConfig config;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  final bool embeddedInTabs;

  @override
  State<RegistrationStudentCard> createState() => _RegistrationStudentCardState();
}

class _RegistrationStudentCardState extends State<RegistrationStudentCard> {
  bool _nameFocused = false;
  bool _ageFocused = false;
  bool _learnFocused = false;
  bool _addressFocused = false;
  bool _healthFocused = false;
  bool _learningFocused = false;

  @override
  void initState() {
    super.initState();
    widget.state.fullNameFocusNode.addListener(_onFocusChange);
    widget.state.ageFocusNode.addListener(_onFocusChange);
    widget.state.learnFocusNode.addListener(_onFocusChange);
    widget.state.addressFocusNode.addListener(_onFocusChange);
    widget.state.healthDetailsFocusNode.addListener(_onFocusChange);
    widget.state.learningDetailsFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.state.fullNameFocusNode.removeListener(_onFocusChange);
    widget.state.ageFocusNode.removeListener(_onFocusChange);
    widget.state.learnFocusNode.removeListener(_onFocusChange);
    widget.state.addressFocusNode.removeListener(_onFocusChange);
    widget.state.healthDetailsFocusNode.removeListener(_onFocusChange);
    widget.state.learningDetailsFocusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _nameFocused = widget.state.fullNameFocusNode.hasFocus;
      _ageFocused = widget.state.ageFocusNode.hasFocus;
      _learnFocused = widget.state.learnFocusNode.hasFocus;
      _addressFocused = widget.state.addressFocusNode.hasFocus;
      _healthFocused = widget.state.healthDetailsFocusNode.hasFocus;
      _learningFocused = widget.state.learningDetailsFocusNode.hasFocus;
    });
  }

  void _notify() => widget.onChanged();

  @override
  Widget build(BuildContext context) {
    final labels = widget.config.labels;
    final s = widget.state;

    return Container(
      margin: EdgeInsets.only(bottom: widget.embeddedInTabs ? 0 : 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.embeddedInTabs)
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: SplashColors.gold.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${widget.index + 1}',
                      style: AppFonts.cairo(
                        fontWeight: FontWeight.w700,
                        color: SplashColors.gold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'بيانات الطالب ${widget.index + 1}',
                    style: AppFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: SplashColors.whiteText,
                    ),
                  ),
                ),
                if (widget.canRemove)
                  IconButton(
                    onPressed: widget.onRemove,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: const Color(0xFFFFB4B4).withValues(alpha: 0.9),
                    ),
                  ),
              ],
            )
          else if (widget.canRemove)
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: widget.onRemove,
                tooltip: 'حذف الطالب',
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: const Color(0xFFFFB4B4).withValues(alpha: 0.9),
                ),
              ),
            ),
          if (!widget.embeddedInTabs || widget.canRemove)
            const SizedBox(height: 20),
          AuthPremiumTextField(
            controller: s.fullNameController,
            focusNode: s.fullNameFocusNode,
            isFocused: _nameFocused,
            label: labels.fullNameLabel,
            hint: 'الاسم الكامل',
            icon: Icons.person_outline_rounded,
            validator: Validators.validateName,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 20),
          if (labels.showBirthdateDiv) ...[
            AuthBirthdateFields(
              dayController: s.birthDayController,
              monthController: s.birthMonthController,
              yearController: s.birthYearController,
              dayFocusNode: s.birthDayFocusNode,
              monthFocusNode: s.birthMonthFocusNode,
              yearFocusNode: s.birthYearFocusNode,
              validator: Validators.validateBirthdateIso,
            ),
            const SizedBox(height: 20),
          ],
          if (labels.showAgeDiv) ...[
            AuthPremiumTextField(
              controller: s.ageController,
              focusNode: s.ageFocusNode,
              isFocused: _ageFocused,
              label: 'العمر *',
              hint: '5',
              icon: Icons.numbers_rounded,
              keyboardType: TextInputType.number,
              validator: Validators.validateAge,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 20),
          ],
          if (labels.showLearnDiv) ...[
            AuthPremiumTextField(
              controller: s.learnController,
              focusNode: s.learnFocusNode,
              isFocused: _learnFocused,
              label: labels.learnCertificateLabel,
              hint: labels.learnCertificateLabel,
              icon: Icons.school_outlined,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 20),
          ],
          AuthActivitySelector(
            activities: widget.config.womanActivities,
            selectedId: s.activityId,
            onSelected: (id) {
              setState(() => s.activityId = id);
              _notify();
            },
            validator: Validators.validateActivity,
          ),
          const SizedBox(height: 20),
          AuthFollowupFields(
            addressController: s.addressController,
            addressFocusNode: s.addressFocusNode,
            isAddressFocused: _addressFocused,
            maritalStatus: s.maritalStatus,
            onMaritalStatusChanged: (v) {
              setState(() => s.maritalStatus = v);
              _notify();
            },
            hasHealthCondition: s.hasHealthCondition,
            onHealthChanged: (v) {
              setState(() => s.hasHealthCondition = v);
              _notify();
            },
            healthDetailsController: s.healthDetailsController,
            healthDetailsFocusNode: s.healthDetailsFocusNode,
            isHealthDetailsFocused: _healthFocused,
            hasLearningDifficulties: s.hasLearningDifficulties,
            onLearningChanged: (v) {
              setState(() => s.hasLearningDifficulties = v);
              _notify();
            },
            learningDetailsController: s.learningDetailsController,
            learningDetailsFocusNode: s.learningDetailsFocusNode,
            isLearningDetailsFocused: _learningFocused,
          ),
          const SizedBox(height: 20),
          AuthStudentPhotoPicker(
            photo: s.pickedPhoto,
            onPhotoChanged: (photo) {
              setState(() => s.pickedPhoto = photo);
              _notify();
            },
          ),
        ],
      ),
    );
  }
}
