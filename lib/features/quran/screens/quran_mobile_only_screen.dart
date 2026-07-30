import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';

/// Shown on Flutter web when the user opens any Quran feature.
class QuranMobileOnlyScreen extends StatelessWidget {
  const QuranMobileOnlyScreen({
    super.key,
    this.appBarTitle = 'القرآن الكريم',
    this.headline = 'المصحف متاح على تطبيق الجوال',
    this.description,
  });

  final String appBarTitle;
  final String headline;
  final String? description;

  static const _defaultDescription =
      'قراءة المصحف ومتابعة خطة الحفظ متاحة في تطبيق الجوال '
      'لتجربة أفضل مع خطوط الصفحات.';

  @override
  Widget build(BuildContext context) {
    final bodyText = description ?? _defaultDescription;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
          },
        ),
        title: Text(
          appBarTitle,
          style: AppFonts.cairo(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Color(0xFF0A1628),
                      Color(0xFF16324A),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.menu_book_rounded,
                            size: 34,
                            color: AppColors.gold.withValues(alpha: 0.95),
                          ),
                          Positioned(
                            right: 18,
                            bottom: 16,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF0A1628),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.smartphone_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      headline,
                      textAlign: TextAlign.center,
                      style: AppFonts.cairo(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      bodyText,
                      textAlign: TextAlign.center,
                      style: AppFonts.cairo(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 15,
                        height: 1.7,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.04),
              const SizedBox(height: 20),
              _InfoCard(
                items: const [
                  _InfoItem(
                    icon: Icons.auto_stories_rounded,
                    text: 'قراءة المصحف بخطوط الصفحات',
                  ),
                  _InfoItem(
                    icon: Icons.translate_rounded,
                    text: 'عرض التفسير والترجمة',
                  ),
                  _InfoItem(
                    icon: Icons.school_rounded,
                    text: 'متابعة خطة التسميع من المعلم',
                  ),
                ],
              ).animate().fadeIn(delay: 120.ms, duration: 350.ms),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.goldLight.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.gold.withValues(alpha: 0.95),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'يمكنك متابعة باقي خدمات المسجد من المتصفح — '
                        'الأذكار، الصلاة، القبلة، وأخبار المسجد.',
                        style: AppFonts.cairo(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          height: 1.65,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 180.ms, duration: 350.ms),
              const SizedBox(height: 24),
              Text(
                AppConstants.appNameFull,
                textAlign: TextAlign.center,
                style: AppFonts.cairo(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoItem {
  const _InfoItem({required this.icon, required this.text});

  final IconData icon;
  final String text;
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.items});

  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 24),
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    items[i].icon,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    items[i].text,
                    style: AppFonts.cairo(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
