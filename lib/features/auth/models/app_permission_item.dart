import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app/models/app_role.dart';

class AppPermissionItem {
  const AppPermissionItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.applicableRoles,
    this.permission,
    this.optional = false,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Permission? permission;
  final bool optional;
  final Set<AppRole> applicableRoles;

  bool appliesTo(AppRole role) => applicableRoles.contains(role);
}

const appPermissionItems = <AppPermissionItem>[
  AppPermissionItem(
    id: 'location',
    title: 'صلاحية الموقع',
    description:
        'يستخدم التطبيق صلاحية الموقع للتأكد من وجودك في المسجد عند تسجيل الحضور والانصراف، '
        ' .',
    icon: Icons.location_on_rounded,
    permission: Permission.locationWhenInUse,
    applicableRoles: {AppRole.parent, AppRole.teacher},
  ),
  AppPermissionItem(
    id: 'microphone',
    title: 'صلاحية الميكروفون',
    description:
        'يُطلب الميكروفون فقط عند بدء مكالمة فيديو أو استخدام الأوامر الصوتية. '
        'يمكنك رفض الطلب ومتابعة استخدام باقي التطبيق.',
    icon: Icons.mic_rounded,
    permission: Permission.microphone,
    optional: true,
    applicableRoles: {AppRole.parent, AppRole.teacher},
  ),
  AppPermissionItem(
    id: 'camera',
    title: 'صلاحية الكاميرا',
    description:
        'تُطلب الكاميرا فقط عند بدء مكالمة فيديو أو مسح رمز QR. '
        'يمكنك رفض الطلب ومتابعة استخدام باقي التطبيق.',
    icon: Icons.videocam_rounded,
    permission: Permission.camera,
    optional: true,
    applicableRoles: {AppRole.parent, AppRole.teacher},
  ),
  AppPermissionItem(
    id: 'bluetooth',
    title: 'البلوتوث (الاتصال بسماعات المكالمة)',
    description:
        'لمكالمات الفيديو: تسمح باستخدام سماعات الرأس أو سماعات البلوتوث '
        'لصوت أوضح. تُستخدم هذه الصلاحية على نظام أندرويد مع أجهزة تدعم البلوتوث.',
    icon: Icons.bluetooth_connected_rounded,
    permission: Permission.bluetoothConnect,
    optional: true,
    applicableRoles: {AppRole.parent, AppRole.teacher},
  ),
  AppPermissionItem(
    id: 'biometrics',
    title: 'البصمة / Face ID',
    description:
        'يُستخدم للتحقق الآمن عند تسجيل الدخول وتأكيد حضور المعلم، '
        'لضمان أن العملية تتم من قبل المستخدم المصرّح له فقط.',
    icon: Icons.fingerprint_rounded,
    permission: null,
    applicableRoles: {AppRole.teacher},
  ),
];
