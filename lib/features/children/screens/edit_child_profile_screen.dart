import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import '../../../core/network/api_exception.dart';
import '../../../core/platform/student_photo_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/student_avatar.dart';
import '../models/child_model.dart';
import '../providers/student_profile_provider.dart';
import '../providers/students_provider.dart';

class EditChildProfileScreen extends ConsumerStatefulWidget {
  final ChildModel child;

  const EditChildProfileScreen({super.key, required this.child});

  @override
  ConsumerState<EditChildProfileScreen> createState() =>
      _EditChildProfileScreenState();
}

class _EditChildProfileScreenState extends ConsumerState<EditChildProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _healthDetailsController = TextEditingController();
  final _learningDetailsController = TextEditingController();

  DateTime? _birthDate;
  String _maritalStatus = 'متزوج / ة';
  bool _hasHealthCondition = false;
  bool _hasLearningDifficulties = false;
  bool _isSubmitting = false;
  bool _isUploadingPhoto = false;
  String? _errorMessage;
  PickedStudentPhoto? _localPhotoPreview;
  String? _avatarUrl;

  static const _maritalOptions = [
    'متزوج / ة',
    'متوفي /ة',
    'مطلق / ة',
    'أعزب',
  ];

  @override
  void initState() {
    super.initState();
    _populateFromChild(widget.child);
  }

  void _populateFromChild(ChildModel child) {
    _fullNameController.text = child.fullName ?? child.name;
    _addressController.text = child.address ?? '';
    _parentNameController.text = child.parentName ?? '';
    _phoneController.text = child.phoneNumber ?? '';
    _birthDate = child.birthDate;
    _hasHealthCondition = child.hasHealthCondition ?? false;
    _hasLearningDifficulties = child.hasLearningDifficulties ?? false;
    _healthDetailsController.text = child.healthConditionDetails ?? '';
    _learningDetailsController.text = child.learningDifficultiesDetails ?? '';
    _avatarUrl = child.avatarUrl;

    final status = child.parentMaritalStatus?.trim();
    if (status != null && status.isNotEmpty) {
      _maritalStatus = status;
    }
  }

  List<String> get _maritalDropdownOptions {
    if (_maritalOptions.contains(_maritalStatus)) {
      return _maritalOptions;
    }
    return [_maritalStatus, ..._maritalOptions];
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _addressController.dispose();
    _parentNameController.dispose();
    _phoneController.dispose();
    _healthDetailsController.dispose();
    _learningDetailsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now().subtract(const Duration(days: 3650)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<StudentPhotoSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                title: Text('اختيار من المعرض', style: AppFonts.cairo()),
                onTap: () => Navigator.pop(context, StudentPhotoSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                title: Text('التقاط صورة', style: AppFonts.cairo()),
                onTap: () => Navigator.pop(context, StudentPhotoSource.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;

    PickedStudentPhoto? picked;
    try {
      picked = await StudentPhotoPicker.pick(source);
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'تعذر اختيار الصورة', style: AppFonts.cairo()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (picked == null || !mounted) return;

    setState(() {
      _localPhotoPreview = picked;
      _isUploadingPhoto = true;
    });

    try {
      final updated = await ref
          .read(studentsApiServiceProvider)
          .uploadStudentPhoto(widget.child.id, picked);
      ref.invalidate(studentProfileProvider(widget.child.id));
      ref.invalidate(studentsProvider);
      if (!mounted) return;
      setState(() {
        _localPhotoPreview = null;
        _avatarUrl = updated.avatarUrl;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم رفع الصورة بنجاح', style: AppFonts.cairo()),
          backgroundColor: AppColors.primary,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _localPhotoPreview = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(studentsApiServiceProvider).updateStudent(widget.child.id, {
        'fullName': _fullNameController.text.trim(),
        'birthDate': _birthDate?.toIso8601String(),
        'address': _addressController.text.trim(),
        'parentName': _parentNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'maritalStatus': _maritalStatus,
        'hasHealthCondition': _hasHealthCondition,
        'healthDetails':
            _hasHealthCondition ? _healthDetailsController.text.trim() : '',
        'hasLearningDifficulties': _hasLearningDifficulties,
        'learningDifficultiesDetails': _hasLearningDifficulties
            ? _learningDetailsController.text.trim()
            : '',
      });

      ref.invalidate(studentProfileProvider(widget.child.id));
      ref.invalidate(studentsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ التغييرات بنجاح', style: AppFonts.cairo()),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'تعذر حفظ التغييرات');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            'تعديل الملف الشخصي',
            style: AppFonts.cairo(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
                Center(child: _buildPhotoSection()),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'نهدف من هذا النموذج إلى فهم حالة الطالب الأجتماعية والتعليمية والصحية لتوفير بيئة مناسبة وتعامل خاص يدعم احتياجاته ويضمن له أفضل بيئة تربوية وتعليمية .',
                          style: AppFonts.cairo(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildSectionTitle('المعلومات الأساسية'),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _fullNameController,
                  label: 'الاسم الرباعي للطالب',
                  icon: Icons.person_outline,
                  validator: (v) => v!.isEmpty ? 'يرجى إدخال الاسم' : null,
                ),
                const SizedBox(height: 16),
                _buildDatePicker(),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _addressController,
                  label: 'عنوان السكن',
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 32),
                _buildSectionTitle('معلومات الوالدين'),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _parentNameController,
                  label: 'اسم الأب/الأم',
                  icon: Icons.family_restroom_outlined,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _phoneController,
                  label: 'رقم الهاتف',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _buildDropdownField(),
                const SizedBox(height: 32),
                _buildSectionTitle('الحالة الصحية والتعليمية'),
                const SizedBox(height: 16),
                _buildSwitchTile(
                  title: 'هل يعاني الطالب من أي حالة صحية أو إعاقة؟',
                  value: _hasHealthCondition,
                  onChanged: (v) => setState(() => _hasHealthCondition = v),
                ),
                if (_hasHealthCondition) ...[
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _healthDetailsController,
                    label: 'يرجى التوضيح',
                    maxLines: 3,
                  ),
                ],
                const SizedBox(height: 16),
                _buildSwitchTile(
                  title: 'هل يعاني الطالب من صعوبات تعليمية أو سلوكية؟',
                  value: _hasLearningDifficulties,
                  onChanged: (v) => setState(() => _hasLearningDifficulties = v),
                ),
                if (_hasLearningDifficulties) ...[
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _learningDetailsController,
                    label: 'يرجى التوضيح',
                    maxLines: 3,
                  ),
                ],
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'حفظ التغييرات',
                            style: AppFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return GestureDetector(
      onTap: _isUploadingPhoto ? null : _pickPhoto,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 4),
            ),
            child: _buildAvatar(),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
            ),
          ),
          if (_isUploadingPhoto)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (_localPhotoPreview != null) {
      return ClipOval(
        child: SizedBox(
          width: 100,
          height: 100,
          child: Image.memory(
            _localPhotoPreview!.bytes,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return StudentAvatar(imageUrl: _avatarUrl, size: 100);
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppFonts.cairo(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: AppFonts.cairo(),
          decoration: InputDecoration(
            prefixIcon:
                icon != null ? Icon(icon, color: AppColors.primary, size: 20) : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تاريخ ميلاد الطالب',
          style: AppFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_outlined,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Text(
                  _birthDate == null
                      ? 'اختر التاريخ'
                      : intl.DateFormat('yyyy/MM/dd').format(_birthDate!),
                  style: AppFonts.cairo(
                    color: _birthDate == null
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الحالة الاجتماعية للوالدين',
          style: AppFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _maritalStatus,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primary),
              items: _maritalDropdownOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: AppFonts.cairo()),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() => _maritalStatus = newValue!);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: AppFonts.cairo(fontSize: 14)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
