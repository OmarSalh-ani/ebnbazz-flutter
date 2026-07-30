import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'network_or_asset_image.dart';

/// Circular student photo from API (AdminAPI /uploads/*).
class StudentAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const StudentAvatar({
    super.key,
    required this.imageUrl,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _placeholder();
    }

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: NetworkOrAssetImage(
          url: imageUrl!,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person_rounded,
        color: AppColors.primary.withValues(alpha: 0.5),
        size: size * 0.55,
      ),
    );
  }
}
