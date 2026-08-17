import 'dart:async';

import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:masged_parent_app/shared/router/app_routes.dart';
import '../../auth/providers/auth_provider.dart';
import '../../children/models/child_model.dart';
import '../../children/providers/students_provider.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/student_avatar.dart';
import '../../../shared/widgets/privacy_policy_link.dart';
import '../../../shared/widgets/settings_option_tile.dart';
import '../../../shared/widgets/delete_account_dialog.dart';
import '../../../core/services/app_review_service.dart';
import '../models/parent_followup_model.dart';
import '../providers/parent_followup_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _parentNameController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isEditing = false;
  bool _isSaving = false;
  String _maritalStatus = 'متزوج / ة';
  bool _formInitialized = false;

  final List<String> _maritalOptions = [
    'متزوج / ة',
    'متوفي /ة',
    'مطلق / ة',
    'أعزب',
  ];

  @override
  void dispose() {
    _parentNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _populateForm(ParentFollowupModel followup, String? authName) {
    _parentNameController.text =
        (followup.parentName?.trim().isNotEmpty == true
                ? followup.parentName
                : authName) ??
            '';
    _addressController.text = followup.address ?? '';
    if (followup.maritalStatus != null &&
        _maritalOptions.contains(followup.maritalStatus)) {
      _maritalStatus = followup.maritalStatus!;
    }
  }

  void _ensureFormInitialized(ParentFollowupModel followup, String? authName) {
    if (_formInitialized) return;
    _populateForm(followup, authName);
    _formInitialized = true;
  }

  Future<void> _toggleEdit(ParentFollowupModel followup, String? authName) async {
    if (_isEditing) {
      setState(() => _isSaving = true);
      try {
        final updated = await ref.read(parentFollowupApiServiceProvider).updateFollowup({
          'parentName': _parentNameController.text.trim(),
          'address': _addressController.text.trim(),
          'maritalStatus': _maritalStatus,
        });

        ref.invalidate(parentFollowupProvider);
        ref.invalidate(studentsProvider);

        final user = ref.read(authProvider).user;
        if (user != null &&
            updated.parentName != null &&
            updated.parentName!.trim().isNotEmpty) {
          await ref.read(authProvider.notifier).updateLocalUser(
                user.copyWith(name: updated.parentName!.trim()),
              );
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ التغييرات بنجاح', style: AppFonts.cairo()),
            backgroundColor: AppColors.primary,
          ),
        );
        setState(() {
          _isEditing = false;
          _formInitialized = false;
        });
      } on ApiException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
        );
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    } else {
      _populateForm(followup, authName);
      setState(() => _isEditing = true);
    }
  }

  void _cancelEdit(ParentFollowupModel followup, String? authName) {
    _populateForm(followup, authName);
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final studentsAsync = ref.watch(studentsProvider);
    final followupAsync = ref.watch(parentFollowupProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('الملف الشخصي',
            style: AppFonts.cairo(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (!context.mounted) return;
              context.go(AppRoutes.login);
            },
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child:
                        const Icon(Icons.person, color: Colors.white, size: 40),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name?.trim().isNotEmpty == true
                              ? user!.name
                              : 'أدخل الاسم',
                          style: AppFonts.cairo(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user?.phone ?? 'رقم الهاتف',
                          style: AppFonts.cairo(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildProfileActionCard(
                    context,
                    title: 'سجل الحضور',
                    icon: Icons.fact_check_rounded,
                    onTap: () => context.go(AppRoutes.attendance),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildProfileActionCard(
                    context,
                    title: 'الحفظ والمتابعة',
                    icon: Icons.menu_book_rounded,
                    onTap: () => context.go(AppRoutes.schedule),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'المعلومات الشخصية',
                    style: AppFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                followupAsync.when(
                  loading: () => const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (followup) {
                    _ensureFormInitialized(followup, user?.name);
                    return TextButton.icon(
                      onPressed: _isSaving
                          ? null
                          : () {
                              if (_isEditing) {
                                _cancelEdit(followup, user?.name);
                              } else {
                                _toggleEdit(followup, user?.name);
                              }
                            },
                      icon: Icon(
                        _isEditing ? Icons.close_rounded : Icons.edit_rounded,
                        size: 18,
                      ),
                      label: Text(
                        _isEditing ? 'إلغاء' : 'تعديل',
                        style: AppFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor:
                            _isEditing ? AppColors.textSecondary : AppColors.primary,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            followupAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'تعذر تحميل بيانات المتابعة',
                  style: AppFonts.cairo(color: AppColors.textSecondary),
                ),
              ),
              data: (followup) {
                _ensureFormInitialized(followup, user?.name);
                return _buildPersonalInfoSection(followup, user?.phone);
              },
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'أبنائي المسجلين',
                    style: AppFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.push(AppRoutes.addChild),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                    'إضافة ابن',
                    style: AppFonts.cairo(fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            studentsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => Text(
                'تعذر تحميل بيانات الأبناء',
                style: AppFonts.cairo(color: AppColors.textSecondary),
              ),
              data: (children) {
                if (children.isEmpty) {
                  return Text(
                    'لا يوجد أبناء مسجلون',
                    style: AppFonts.cairo(color: AppColors.textSecondary),
                  );
                }
                return Column(
                  children: [
                    for (int i = 0; i < children.length; i++) ...[
                      _buildChildListItem(context, children[i]),
                      if (i < children.length - 1) const SizedBox(height: 16),
                    ],
                  ],
                );
              },
            ),
            if (_isEditing) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : () => _toggleEdit(
                            followupAsync.asData!.value,
                            user?.name,
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'حفظ التغييرات',
                          style: AppFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SettingsOptionTile(
              icon: Icons.star_outline_rounded,
              title: 'قيّم التطبيق',
              subtitle: 'ساعدنا بترك تقييمك على المتجر',
              onTap: () => unawaited(AppReviewService.promptNow()),
            ),
            const SizedBox(height: 12),
            const PrivacyPolicyLink(),
            const SizedBox(height: 12),
            SettingsOptionTile(
              icon: Icons.delete_outline_rounded,
              title: 'حذف الحساب',
              subtitle: 'حذف حسابك وبياناتك الشخصية نهائياً',
              onTap: () async {
                final deleted = await showDeleteAccountDialog(
                  context,
                  onConfirm: (password) async {
                    await ref.read(authProvider.notifier).deleteAccount(password);
                  },
                );
                if (deleted && context.mounted) {
                  context.go(AppRoutes.login);
                }
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection(ParentFollowupModel followup, String? phone) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: _isEditing
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEditField(
                  controller: _parentNameController,
                  label: 'الاسم بالكامل',
                  hint: 'أدخل الاسم',
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 16),
                _buildReadOnlyField(
                  label: 'رقم الهاتف',
                  value: phone ?? 'غير محدد',
                  icon: Icons.phone_outlined,
                ),
                const SizedBox(height: 16),
                _buildEditField(
                  controller: _addressController,
                  label: 'عنوان السكن',
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 16),
                _buildMaritalDropdown(),
              ],
            )
          : Column(
              children: [
                _buildDetailRow(
                  'الاسم بالكامل:',
                  followup.parentName?.trim().isNotEmpty == true
                      ? followup.parentName!
                      : 'أدخل الاسم',
                  Icons.person_outline_rounded,
                  isHint: followup.parentName?.trim().isNotEmpty != true,
                ),
                const Divider(height: 24),
                _buildDetailRow(
                  'رقم الهاتف:',
                  phone ?? 'غير محدد',
                  Icons.phone_outlined,
                ),
                const Divider(height: 24),
                _buildDetailRow(
                  'عنوان السكن:',
                  followup.address?.trim().isNotEmpty == true
                      ? followup.address!
                      : 'غير محدد',
                  Icons.location_on_outlined,
                ),
                const Divider(height: 24),
                _buildDetailRow(
                  'الحالة الاجتماعية:',
                  followup.maritalStatus?.trim().isNotEmpty == true
                      ? followup.maritalStatus!
                      : 'غير محدد',
                  Icons.people_outline_rounded,
                ),
              ],
            ),
    );
  }

  Widget _buildEditField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: AppFonts.cairo(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: AppFonts.cairo(color: AppColors.textSecondary, fontSize: 14),
        labelStyle: AppFonts.cairo(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppFonts.cairo(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
      ),
      child: Text(
        value,
        style: AppFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildMaritalDropdown() {
    return DropdownButtonFormField<String>(
      value: _maritalOptions.contains(_maritalStatus)
          ? _maritalStatus
          : _maritalOptions.first,
      decoration: InputDecoration(
        labelText: 'الحالة الاجتماعية',
        labelStyle: AppFonts.cairo(color: AppColors.textSecondary),
        prefixIcon: const Icon(Icons.people_outline_rounded,
            color: AppColors.primary, size: 20),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
      ),
      items: _maritalOptions
          .map((o) => DropdownMenuItem(value: o, child: Text(o, style: AppFonts.cairo())))
          .toList(),
      onChanged: (v) {
        if (v != null) setState(() => _maritalStatus = v);
      },
    );
  }

  Widget _buildChildListItem(BuildContext context, ChildModel child) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.childProfile, extra: child),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            StudentAvatar(
              imageUrl: child.avatarUrl,
              size: 50,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child.firstName,
                    style: AppFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  if (child.group.isNotEmpty)
                    Text(
                      child.group,
                    style: AppFonts.cairo(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    bool isHint = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppFonts.cairo(
                      fontSize: 12, color: AppColors.textSecondary)),
              Text(value,
                  style: AppFonts.cairo(
                      fontSize: 14,
                      fontWeight: isHint ? FontWeight.w500 : FontWeight.bold,
                      color: isHint
                          ? AppColors.textSecondary
                          : AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileActionCard(BuildContext context,
      {required String title,
      required IconData icon,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 30),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
