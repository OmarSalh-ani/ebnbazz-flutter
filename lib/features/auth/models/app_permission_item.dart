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
        'يستخدم التطبيق المايكروفون لمكالمات الفيديو مع المعلم عند الموافقة، '
        'وللمعلّم أيضاً للأوامر الصوتية مثل تحضير الطلاب وتسجيل الانصراف وإعداد خطط الحفظ.',
    icon: Icons.mic_rounded,
    permission: Permission.microphone,
    applicableRoles: {AppRole.parent, AppRole.teacher},
  ),
  AppPermissionItem(
    id: 'camera',
    title: 'صلاحية الكاميرا',
    description:
        'يستخدم التطبيق الكاميرا لمكالمات الفيديو مع المعلم، وللمعلّم أيضاً '
        'لمسح رمز QR عند تسجيل حضور الطلاب والتحقق السريع من هوية الطالب داخل الحلقة.',
    icon: Icons.videocam_rounded,
    permission: Permission.camera,
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
