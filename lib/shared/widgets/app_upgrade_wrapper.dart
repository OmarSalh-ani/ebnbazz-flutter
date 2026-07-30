import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

import '../../core/services/app_upgrader_config.dart';
import '../router/app_router.dart';

class AppUpgradeWrapper extends StatefulWidget {
  const AppUpgradeWrapper({super.key, required this.child});

  final Widget child;

  @override
  State<AppUpgradeWrapper> createState() => _AppUpgradeWrapperState();
}

class _AppUpgradeWrapperState extends State<AppUpgradeWrapper> {
  late final Upgrader _upgrader = createAppUpgrader();

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return widget.child;

    return UpgradeAlert(
      upgrader: _upgrader,
      navigatorKey: rootNavigatorKey,
      child: widget.child,
    );
  }
}
