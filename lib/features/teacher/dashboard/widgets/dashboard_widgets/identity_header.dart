import 'package:flutter/material.dart';

class IdentityHeader extends StatelessWidget {
  const IdentityHeader({super.key});

  static const _assetPath = 'assets/images/LoginHeaderImage.png';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        _assetPath,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }
}
