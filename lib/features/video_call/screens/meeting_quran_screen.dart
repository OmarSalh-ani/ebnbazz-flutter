import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../quran/quran_route.dart';
import '../../quran/screens/quran_main_screen.dart';

/// Teacher-only Quran reader during a video call (no screen sharing).
class MeetingQuranScreen extends StatelessWidget {
  const MeetingQuranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: Text(
            'المصحف',
            style: AppFonts.cairo(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'العودة للمكالمة',
          ),
        ),
        body: Navigator(
          onGenerateRoute: (_) {
            return MaterialPageRoute<void>(
              builder: (_) => buildQuranScreen(const QuranMainScreen()),
            );
          },
        ),
      ),
    );
  }
}
