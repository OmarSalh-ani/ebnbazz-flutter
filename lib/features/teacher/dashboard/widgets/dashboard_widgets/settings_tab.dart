import 'dart:async';

import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:masged_parent_app/core/theme/app_colors.dart';
import 'package:masged_parent_app/core/theme/app_theme_extensions.dart';
import 'package:masged_parent_app/shared/widgets/settings_option_tile.dart';
import 'package:masged_parent_app/shared/widgets/privacy_policy_link.dart';
import 'package:masged_parent_app/shared/widgets/delete_account_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:masged_parent_app/shared/router/app_routes.dart';
import 'package:masged_parent_app/core/services/app_review_service.dart';
import '../../models/dashboard_models.dart';
import 'change_password_dialog.dart';
import 'language_notice.dart';
import 'logout_confirmation_dialog.dart';
import 'support_dialog.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../screens/teacher_admin_notes_screen.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({
    super.key,
    required this.data,
  });

  final DashboardPageData? data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = context.appPrimary;
    final teacherName = data?.teacherName ?? 'المعلم';
    final circleName = data?.circleName.isNotEmpty == true
        ? data!.circleName
        : 'حلقة التحفيظ';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  primary,
                  primary.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.25),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: context.appPrimaryLight,
                    child: Text(
                      teacherName.isNotEmpty ? teacherName[0] : 'م',
                      style: AppFonts.cairo(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  teacherName,
                  textAlign: TextAlign.center,
                  style: AppFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    circleName,
                    textAlign: TextAlign.center,
                    style: AppFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'إعدادات التطبيق',
            style: AppFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SettingsOptionTile(
            icon: Icons.campaign_outlined,
            title: 'إشعارات الإدارة',
            subtitle: 'ملاحظات وإشعارات من إدارة المسجد',
            trailing: (data?.unreadAdminNotesCount ?? 0) > 0
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${data!.unreadAdminNotesCount}',
                      style: AppFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  )
                : null,
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const TeacherAdminNotesScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          SettingsOptionTile(
            icon: Icons.lock_outline_rounded,
            title: 'تغيير كلمة المرور',
            subtitle: 'تحديث كلمة المرور الخاصة بحسابك',
            onTap: () => showChangePasswordDialog(context, ref),
          ),
          const SizedBox(height: 12),
          SettingsOptionTile(
            icon: Icons.language_rounded,
            title: 'لغة التطبيق',
            subtitle: 'العربية (اللغة الافتراضية)',
            trailing: Text(
              'العربية',
              style: AppFonts.cairo(
                fontSize: 12,
                color: primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () => showLanguageNotice(context),
          ),
          const SizedBox(height: 12),
          SettingsOptionTile(
            icon: Icons.help_outline_rounded,
            title: 'الدعم والمساعدة',
            subtitle: 'اتصل بنا للحصول على الدعم الفني',
            onTap: () => showSupportDialog(context),
          ),
          const SizedBox(height: 12),
          SettingsOptionTile(
            icon: Icons.privacy_tip_outlined,
            title: 'سياسة الخصوصية',
            subtitle: 'كيف نجمع ونستخدم بياناتك',
            onTap: openPrivacyPolicy,
          ),
          const SizedBox(height: 12),
          SettingsOptionTile(
            icon: Icons.delete_outline_rounded,
            title: 'حذف الحساب',
            subtitle: 'حذف حسابك وبياناتك الشخصية نهائياً',
            onTap: () async {
              final deleted = await showDeleteAccountDialog(
                context,
                onConfirm: (password) async {
                  await ref.read(authControllerProvider.notifier).deleteAccount(password);
                },
              );
              if (deleted && context.mounted) {
                context.go(AppRoutes.login);
              }
            },
          ),
          const SizedBox(height: 12),
          SettingsOptionTile(
            icon: Icons.star_outline_rounded,
            title: 'قيّم التطبيق',
            subtitle: 'ساعدنا بترك تقييمك على المتجر',
            onTap: () => unawaited(AppReviewService.promptNow()),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => showLogoutConfirmationDialog(context, ref),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const SizedBox.shrink(),
            label: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    AppColors.error,
                    AppColors.error.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.error.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Container(
                height: 56,
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.logout_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'تسجيل الخروج',
                      style: AppFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
