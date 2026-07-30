import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/student_avatar.dart';
import '../models/child_model.dart';
import '../providers/student_profile_provider.dart';
import 'edit_child_profile_screen.dart';
import 'parent_memorizing_archive_screen.dart';
import '../widgets/child_plan_table_section.dart';

class ChildProfileScreen extends ConsumerWidget {
  final ChildModel child;

  const ChildProfileScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(studentProfileProvider(child.id));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: profileAsync.when(
        loading: () => _buildLoadingScaffold(),
        error: (_, __) => _buildErrorScaffold(ref),
        data: (profile) => _buildScaffold(context, ref, profile),
      ),
    );
  }

  Future<void> _openEditProfile(BuildContext context, WidgetRef ref, ChildModel profile) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditChildProfileScreen(child: profile),
      ),
    );
    ref.invalidate(studentProfileProvider(profile.id));
  }

  Widget _buildLoadingScaffold() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'ملف الابن',
          style: AppFonts.cairo(fontWeight: FontWeight.bold),
        ),
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorScaffold(WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'ملف الابن',
          style: AppFonts.cairo(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'تعذر تحميل ملف الابن',
              style: AppFonts.cairo(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => ref.invalidate(studentProfileProvider(child.id)),
              child: Text(
                'إعادة المحاولة',
                style: AppFonts.cairo(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBirthDate(DateTime? date) {
    if (date == null) return 'غير محدد';
    return intl.DateFormat('yyyy/MM/dd').format(date);
  }

  Widget _buildScaffold(BuildContext context, WidgetRef ref, ChildModel profile) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'ملف الابن',
          style: AppFonts.cairo(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
            onPressed: () => _openEditProfile(context, ref, profile),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProfileHeader(profile),
            const SizedBox(height: 32),
            _buildSectionTitle('جدول الخطة', Icons.table_chart_rounded),
            const SizedBox(height: 12),
            ChildPlanTableSection(studentId: profile.id),
            const SizedBox(height: 32),
            _buildMemorizingArchiveSection(context, profile),
            const SizedBox(height: 32),
            _buildSectionTitle('سجل الحضور', Icons.calendar_today_rounded),
            const SizedBox(height: 12),
            _buildAttendanceStats(profile),
            const SizedBox(height: 32),
            if (profile.notes != null && profile.notes!.isNotEmpty) ...[
              _buildSectionTitle('ملاحظات المعلم', Icons.note_alt_rounded),
              const SizedBox(height: 12),
              _buildTeacherNotes(profile),
              const SizedBox(height: 32),
            ],
            _buildSectionTitle('المعلومات الشخصية', Icons.badge_rounded),
            const SizedBox(height: 12),
            _buildPersonalDetails(profile),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.1)),
              ),
              child: Text(
                'نهدف من هذا النموذج إلى فهم حالة الطالب الأجتماعية والتعليمية والصحية لتوفير بيئة مناسبة وتعامل خاص يدعم احتياجاته ويضمن له أفضل بيئة تربوية وتعليمية .',
                style: AppFonts.cairo(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalDetails(ChildModel profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildDetailRow('الاسم الرباعي:', profile.fullName ?? profile.name, Icons.person_pin_rounded),
          const Divider(height: 24),
          _buildDetailRow('تاريخ الميلاد:', _formatBirthDate(profile.birthDate), Icons.cake_rounded),
          const Divider(height: 24),
          _buildDetailRow('عنوان السكن:', profile.address ?? 'غير محدد', Icons.location_on_rounded),
          const Divider(height: 24),
          _buildDetailRow('اسم الأب/الأم:', profile.parentName ?? 'غير محدد', Icons.family_restroom_rounded),
          const Divider(height: 24),
          _buildDetailRow('رقم الهاتف:', profile.phoneNumber ?? 'غير محدد', Icons.phone_rounded),
          const Divider(height: 24),
          _buildDetailRow('الحالة الاجتماعية للوالدين:', profile.parentMaritalStatus ?? 'غير محدد', Icons.people_rounded),
          const Divider(height: 24),
          _buildStatusRow('الحالة الصحية:', profile.hasHealthCondition ?? false, profile.healthConditionDetails),
          const Divider(height: 24),
          _buildStatusRow('صعوبات تعليمية:', profile.hasLearningDifficulties ?? false, profile.learningDifficultiesDetails),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppFonts.cairo(fontSize: 12, color: AppColors.textSecondary)),
              Text(value, style: AppFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, bool hasIssue, String? details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(hasIssue ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                 size: 18, color: hasIssue ? Colors.orange : Colors.green),
            const SizedBox(width: 12),
            Text(label, style: AppFonts.cairo(fontSize: 12, color: AppColors.textSecondary)),
            const Spacer(),
            Text(hasIssue ? 'نعم' : 'لا',
                 style: AppFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: hasIssue ? Colors.orange : Colors.green)),
          ],
        ),
        if (hasIssue && details != null && details.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(details, style: AppFonts.cairo(fontSize: 13, color: Colors.orange.shade800)),
          ),
        ],
      ],
    );
  }

  Widget _buildProfileHeader(ChildModel profile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 4),
            ),
            child: StudentAvatar(imageUrl: profile.avatarUrl, size: 100),
          ),
          const SizedBox(height: 20),
          Text(
            profile.name,
            style: AppFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('تاريخ الميلاد:', _formatBirthDate(profile.birthDate), Icons.cake_rounded),
          const SizedBox(height: 12),
          _buildInfoRow('المستوى:', profile.level, Icons.school_rounded),
          const SizedBox(height: 12),
          _buildInfoRow('المجموعة:', profile.group, Icons.groups_rounded),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(
            label,
            style: AppFonts.cairo(fontSize: 14, color: AppColors.textSecondary),
          ),
          const Spacer(),
          Text(
            value,
            style: AppFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemorizingArchiveSection(BuildContext context, ChildModel profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('أرشيف الحفظ', Icons.menu_book_rounded),
        const SizedBox(height: 12),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ParentMemorizingArchiveScreen(
                    studentId: profile.id,
                    studentName: profile.name,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.history_edu_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'عرض سجلات الحفظ والمراجعة',
                          style: AppFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'بحث بالسورة وعرض تفاصيل كل سجل',
                          style: AppFonts.cairo(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_left_rounded,
                    color: AppColors.textHint,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: AppFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceStats(ChildModel profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatBox('نسبة الحضور', '${profile.attendancePercent}%', AppColors.success),
              _buildStatBox('أيام الغياب', '${profile.absentDaysThisMonth} أيام', AppColors.error),
              _buildStatBox('التأخير', '${profile.lateCount} مرات', AppColors.warning),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'سجل الأسبوع الحالي',
            style: AppFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          _buildWeeklyBar(profile),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: AppFonts.cairo(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildWeeklyBar(ChildModel profile) {
    const dayKeys = [
      'السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة',
    ];
    const dayLabels = ['سبت', 'أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة'];
    final weekly = profile.weeklyAttendance ?? {};

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final isPresent = weekly[dayKeys[index]];
        final isFuture = isPresent == null;
        return Column(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: isFuture
                    ? AppColors.border
                    : (isPresent == true ? AppColors.success : AppColors.error),
                shape: BoxShape.circle,
              ),
              child: isFuture
                  ? null
                  : Icon(
                      isPresent == true
                          ? Icons.check_rounded
                          : Icons.close_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
            ),
            const SizedBox(height: 4),
            Text(
              dayLabels[index],
              style: AppFonts.cairo(fontSize: 10, color: AppColors.textHint),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildTeacherNotes(ChildModel profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (profile.teacherName != null &&
              profile.teacherName!.trim().isNotEmpty) ...[
            Row(
              children: [
                const CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.primary,
                  child: Icon(
                    Icons.person_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  profile.teacherName!,
                  style: AppFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Text(
            profile.notes!,
            style: AppFonts.cairo(fontSize: 14, color: AppColors.textPrimary, height: 1.6),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1);
  }
}
