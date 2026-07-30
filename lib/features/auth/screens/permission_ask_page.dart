import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app/models/app_role.dart';
import '../../../app/providers/app_role_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_permission_helper.dart';
import '../../../core/utils/platform_helper.dart';
import '../../../shared/router/app_routes.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/privacy_policy_link.dart';
import '../models/app_permission_item.dart';
import '../providers/permission_onboarding_provider.dart';

class PermissionAskPage extends ConsumerStatefulWidget {
  const PermissionAskPage({super.key});

  @override
  ConsumerState<PermissionAskPage> createState() => _PermissionAskPageState();
}

class _PermissionAskPageState extends ConsumerState<PermissionAskPage> {
  bool _isRequesting = false;
  final Map<String, PermissionStatus> _statusById = {};

  List<AppPermissionItem> get _visibleItems {
    final role = ref.watch(appRoleProvider);
    Iterable<AppPermissionItem> items =
        role == null ? appPermissionItems : appPermissionItems.where((item) => item.appliesTo(role));
    // BLUETOOTH_CONNECT runtime prompt exists on Android; iOS routes call audio without this row.
    if (kIsWeb || !isAndroid) {
      items = items.where((item) => item.id != 'bluetooth');
    }
    return items.toList();
  }

  Future<void> _refreshStatuses() async {
    final statuses = <String, PermissionStatus>{};
    for (final item in _visibleItems) {
      if (item.permission != null) {
        statuses[item.id] = await AppPermissionHelper.statusFor(item);
      }
    }
    if (mounted) setState(() => _statusById.addAll(statuses));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshStatuses());
  }

  Future<void> _finish() async {
    if (_isRequesting) return;

    setState(() => _isRequesting = true);
    try {
      for (final item in _visibleItems) {
        if (item.permission == null) continue;

        var status = await AppPermissionHelper.statusFor(item);
        if (!status.isGranted && !status.isLimited) {
          status = await AppPermissionHelper.requestFor(item);
        }
        if (mounted) {
          setState(() => _statusById[item.id] = status);
        }
      }

      await ref.read(permissionOnboardingProvider.notifier).markCompleted();
      if (!mounted) return;
      _navigateNext();
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  void _navigateNext() {
    final role = ref.read(appRoleProvider);
    final destination = role == AppRole.teacher
        ? AppRoutes.teacherDashboard
        : AppRoutes.home;
    context.go(destination);
  }

  @override
  Widget build(BuildContext context) {
    final items = _visibleItems;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildInfoBanner(),
                      const SizedBox(height: 20),
                      ...items.asMap().entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _PermissionCard(
                                item: entry.value,
                                status: _statusById[entry.value.id],
                              )
                                  .animate(delay: (80 * entry.key).ms)
                                  .fade(duration: 350.ms)
                                  .slideY(
                                    begin: 0.08,
                                    end: 0,
                                    duration: 350.ms,
                                    curve: Curves.easeOut,
                                  ),
                            ),
                          ),
                      const SizedBox(height: 8),
                      _buildPrivacyNote(),
                      const SizedBox(height: 12),
                      const PrivacyPolicyLink(),
                    ],
                  ),
                ),
              ),
              _buildBottomActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.verified_user_rounded,
            color: Colors.white,
            size: 42,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'صلاحيات التطبيق',
          style: AppFonts.cairo(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'نحترم خصوصيتك. فيما يلي الصلاحيات التي قد يطلبها التطبيق '
          'مع توضيح سبب استخدام كل منها.',
          textAlign: TextAlign.center,
          style: AppFonts.cairo(
            fontSize: 14,
            height: 1.6,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    ).animate().fade(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.info, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'عند الضغط على «السماح والمتابعة» ستظهر لك نوافذ النظام '
              'لطلب كل صلاحية مع توضيح سبب استخدامها.',
              style: AppFonts.cairo(
                fontSize: 13,
                height: 1.55,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.privacy_tip_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'الخصوصية والأمان',
                style: AppFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• لا نبيع بياناتك ولا نشاركها مع أطراف ثالثة لأغراض تسويقية.\n'
            '• تُستخدم الصلاحيات فقط لتقديم ميزات التطبيق (بما فيها مكالمات الفيديو داخل التطبيق).\n'
            '• يمكنك سحب أي صلاحية في أي وقت من إعدادات الهاتف.',
            style: AppFonts.cairo(
              fontSize: 12.5,
              height: 1.7,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: CustomButton(
        text: 'السماح والمتابعة',
        icon: Icons.check_circle_outline_rounded,
        isLoading: _isRequesting,
        onPressed: _finish,
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.item,
    required this.status,
  });

  final AppPermissionItem item;
  final PermissionStatus? status;

  @override
  Widget build(BuildContext context) {
    final isGranted = status?.isGranted == true || status?.isLimited == true;
    final isDeniedForever = status?.isPermanentlyDenied == true;
    final hasRuntimePermission = item.permission != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isGranted
              ? AppColors.success.withValues(alpha: 0.35)
              : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(item.icon, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: AppFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          _buildBadge(
                            label: item.optional ? 'اختيارية' : 'مطلوبة',
                            color: item.optional
                                ? AppColors.warning
                                : AppColors.primary,
                            background: item.optional
                                ? AppColors.warningLight
                                : AppColors.primaryLight,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.description,
                        style: AppFonts.cairo(
                          fontSize: 13,
                          height: 1.55,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildStatusChip(
              isGranted: isGranted,
              isDeniedForever: isDeniedForever,
              customLabel: hasRuntimePermission ? null : 'تُطلب عند الاستخدام',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge({
    required String label,
    required Color color,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppFonts.cairo(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusChip({
    required bool isGranted,
    required bool isDeniedForever,
    String? customLabel,
  }) {
    late final String label;
    late final Color color;
    late final Color background;
    late final IconData icon;

    if (customLabel != null) {
      label = customLabel;
      color = AppColors.info;
      background = AppColors.infoLight;
      icon = Icons.schedule_rounded;
    } else if (isGranted) {
      label = 'تم منح الصلاحية';
      color = AppColors.success;
      background = AppColors.successLight;
      icon = Icons.check_circle_rounded;
    } else if (isDeniedForever) {
      label = 'مرفوضة من الإعدادات';
      color = AppColors.error;
      background = AppColors.errorLight;
      icon = Icons.block_rounded;
    } else {
      label = 'لم تُمنح بعد';
      color = AppColors.textSecondary;
      background = AppColors.inputFill;
      icon = Icons.radio_button_unchecked_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppFonts.cairo(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
