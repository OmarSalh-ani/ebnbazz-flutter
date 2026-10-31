import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../public_home_constants.dart';
import '../utils/public_home_utils.dart';

class PublicHomeRegisterCta extends StatelessWidget {
  const PublicHomeRegisterCta({
    super.key,
    required this.menEnabled,
    required this.womenEnabled,
  });

  final bool menEnabled;
  final bool womenEnabled;

  @override
  Widget build(BuildContext context) {
    if (!menEnabled && !womenEnabled) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF0D5C6D), Color(0xFF09404C)],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              top: -40,
              left: -20,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(PublicHomeConstants.accentGold)
                      .withValues(alpha: 0.12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'انضم إلينا',
                    style: AppFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(PublicHomeConstants.accentGold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ابدأ رحلتك التعليمية اليوم',
                    style: AppFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'سجّل الآن في برامجنا واستفد من بيئة تعليمية متميزة',
                    style: AppFonts.cairo(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.88),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (menEnabled)
                        _CtaButton(
                          label: 'تسجيل الرجال',
                          onTap: () => launchPublicUrl(
                            PublicHomeConstants.registrationMen,
                          ),
                        ),
                      if (womenEnabled)
                        _CtaButton(
                          label: 'تسجيل النساء',
                          onTap: () => launchPublicUrl(
                            PublicHomeConstants.registrationWomen,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  const _CtaButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(PublicHomeConstants.accentGold),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_add_alt_1_rounded, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppFonts.cairo(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
