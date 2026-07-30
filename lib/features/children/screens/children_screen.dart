import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../models/child_model.dart';
import '../providers/students_provider.dart';
import 'package:masged_parent_app/shared/router/app_routes.dart';
import '../../../shared/widgets/student_avatar.dart';

class ChildrenScreen extends ConsumerWidget {
  const ChildrenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            'أبنائي',
            style: AppFonts.cairo(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(studentsProvider);
            await ref.read(studentsProvider.future);
          },
          child: studentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                Center(
                  child: Column(
                    children: [
                      Text(
                        'تعذر تحميل بيانات الأبناء',
                        style: AppFonts.cairo(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => ref.invalidate(studentsProvider),
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
              ],
            ),
            data: (children) {
              if (children.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                    Center(
                      child: Text(
                        'لا يوجد أبناء مسجلون',
                        style: AppFonts.cairo(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                );
              }

              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                itemCount: children.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) =>
                    _buildChildCard(context, children[index]),
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push(AppRoutes.addChild),
          backgroundColor: AppColors.primary,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
        ),
      ),
    );
  }

  Widget _buildChildCard(BuildContext context, ChildModel child) {
    Color statusColor = Colors.grey;
    String statusText = 'غير معروف';

    switch (child.status) {
      case ChildStatus.inMasged:
        statusColor = const Color(0xFF10B981);
        statusText = 'في المسجد';
        break;
      case ChildStatus.left:
        statusColor = const Color(0xFFF59E0B);
        statusText = 'غادر المسجد';
        break;
      case ChildStatus.vacation:
        statusColor = const Color(0xFF64748B);
        statusText = 'إجازة اليوم';
        break;
      case ChildStatus.absent:
        statusColor = const Color(0xFFEF4444);
        statusText = 'غائب اليوم';
        break;
    }

    return GestureDetector(
      onTap: () => context.push(AppRoutes.childProfile, extra: child),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          statusColor.withOpacity(0.2),
                          statusColor.withOpacity(0.05),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: StudentAvatar(
                      imageUrl: child.avatarUrl,
                      size: 60,
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.firstName,
                      style: AppFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.school_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${child.level} - ${child.group}',
                            style: AppFonts.cairo(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    if (child.logTime != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'دخول: ${child.logTime}',
                        style: AppFonts.cairo(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                    if (child.status == ChildStatus.left &&
                        child.departureTime != null) ...[
                      Text(
                        'خروج: ${child.departureTime}',
                        style: AppFonts.cairo(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusText,
                        style: AppFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: Colors.grey.withOpacity(0.3)),
            ],
          ),
        ),
      ),
    );
  }
}
