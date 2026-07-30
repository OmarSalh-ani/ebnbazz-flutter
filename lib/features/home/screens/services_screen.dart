import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';

import '../../../shared/widgets/quick_services.dart';

/// Shared services grid — parent [MainScaffold] tab and teacher dashboard tab.
class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key, this.embeddedInDashboard = false});

  /// When true, only the grid is shown (outer [Scaffold] is provided by host).
  final bool embeddedInDashboard;

  static const _backgroundColor = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    final body = ColoredBox(
      color: _backgroundColor,
      child: QuickServicesGrid(),
    );

    if (embeddedInDashboard) {
      return body;
    }

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          'الخدمات',
          style: AppFonts.cairo(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: body,
    );
  }
}
