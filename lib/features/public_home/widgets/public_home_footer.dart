import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/router/app_routes.dart';
import '../../../shared/widgets/network_or_asset_image.dart';
import '../../../shared/widgets/privacy_policy_link.dart' show openPrivacyPolicy;
import '../models/public_index_content.dart';
import '../public_home_constants.dart';
import '../utils/public_home_utils.dart';

class PublicHomeFooter extends StatelessWidget {
  const PublicHomeFooter({
    super.key,
    required this.about,
    required this.socialLinks,
    required this.masgedName,
    this.logoUrl,
    required this.menRegistrationEnabled,
    required this.womenRegistrationEnabled,
  });

  final AboutInfo about;
  final List<SocialLink> socialLinks;
  final String masgedName;
  final String? logoUrl;
  final bool menRegistrationEnabled;
  final bool womenRegistrationEnabled;

  @override
  Widget build(BuildContext context) {
    final name = masgedName.isNotEmpty ? masgedName : PublicHomeConstants.defaultMasgedName;
    final year = DateTime.now().year;

    return Container(
      color: const Color(0xFF071B3A),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (logoUrl != null && logoUrl!.isNotEmpty)
            SizedBox(
              height: 56,
              child: NetworkOrAssetImage(
                url: logoUrl!,
                fit: BoxFit.contain,
              ),
            )
          else
            Text(
              name,
              style: AppFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          const SizedBox(height: 20),
          Text(
            'عن المركز',
            style: AppFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(PublicHomeConstants.accentGold),
            ),
          ),
          const SizedBox(height: 8),
          if (about.content.isNotEmpty)
            Text(
              about.content,
              style: AppFonts.cairo(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.6,
              ),
            ),
          if ((about.address ?? '').isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 20,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    about.address!,
                    style: AppFonts.cairo(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if ((about.mapsUrl ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => launchPublicUrl(about.mapsUrl!),
              icon: const Icon(Icons.map_outlined, size: 18),
              label: const Text('عرض على الخريطة'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(PublicHomeConstants.accentGold),
                textStyle: AppFonts.cairo(fontWeight: FontWeight.w700),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'روابط سريعة',
            style: AppFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(PublicHomeConstants.accentGold),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FooterChip(
                label: 'تسجيل الدخول',
                onTap: () => context.push(AppRoutes.login),
              ),
              _FooterChip(
                label: 'الأخبار',
                onTap: () => context.push(AppRoutes.masgedNews),
              ),
              _FooterChip(
                label: 'إصدارات المركز',
                onTap: () => context.push(AppRoutes.library),
              ),
              if (menRegistrationEnabled)
                _FooterChip(
                  label: 'تسجيل الرجال',
                  onTap: () =>
                      launchPublicUrl(PublicHomeConstants.registrationMen),
                ),
              if (womenRegistrationEnabled)
                _FooterChip(
                  label: 'تسجيل النساء',
                  onTap: () =>
                      launchPublicUrl(PublicHomeConstants.registrationWomen),
                ),
            ],
          ),
          if (socialLinks.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'شعاراتنا',
              style: AppFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(PublicHomeConstants.accentGold),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final link in socialLinks)
                  _SocialChip(link: link),
              ],
            ),
          ],
          const SizedBox(height: 28),
          const Divider(color: Color(0xFF163A6B)),
          const SizedBox(height: 16),
          if (AppConstants.hasPrivacyPolicyUrl) ...[
            TextButton(
              onPressed: openPrivacyPolicy,
              child: Text(
                'سياسة الخصوصية',
                style: AppFonts.cairo(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.75),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            '© $year $name. جميع الحقوق محفوظة.',
            style: AppFonts.cairo(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterChip extends StatelessWidget {
  const _FooterChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: AppFonts.cairo(fontSize: 12)),
      onPressed: onTap,
      backgroundColor: Colors.white.withValues(alpha: 0.08),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
      labelStyle: AppFonts.cairo(color: Colors.white.withValues(alpha: 0.9)),
    );
  }
}

class _SocialChip extends StatelessWidget {
  const _SocialChip({required this.link});

  final SocialLink link;

  IconData _iconForPlatform() {
    final name = link.platformName.toLowerCase();
    if (name.contains('whatsapp')) return Icons.chat_rounded;
    if (name.contains('twitter') || name.contains('x')) {
      return Icons.alternate_email_rounded;
    }
    if (name.contains('youtube')) return Icons.play_circle_outline_rounded;
    if (name.contains('instagram')) return Icons.camera_alt_outlined;
    if (name.contains('facebook')) return Icons.facebook_rounded;
    return Icons.link_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => launchPublicUrl(link.url),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_iconForPlatform(), size: 18, color: AppColors.primaryLight),
            const SizedBox(width: 8),
            Text(
              link.platformName,
              style: AppFonts.cairo(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
