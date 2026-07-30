import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import 'package:masged_parent_app/teacher_core/network/api_exception.dart';
import 'package:masged_parent_app/teacher_core/services/location_service.dart';
import 'package:masged_parent_app/teacher_core/services/teacher_attendance_fingerprint_service.dart';
import 'package:masged_parent_app/core/theme/app_colors.dart';
import '../../meetings/screens/meetings_screen.dart';
import '../screens/teacher_attendance_log_screen.dart';
import '../helpers/teacher_attendance_duration.dart';
import '../models/dashboard_models.dart';
import '../models/teacher_attendance_models.dart';
import '../providers/teacher_attendance_providers.dart';
import 'device_re_enrollment_dialog.dart';
import 'mosque_proximity_banner.dart';

class TeacherAttendanceContainer extends ConsumerStatefulWidget {
  const TeacherAttendanceContainer({
    super.key,
    required this.data,
  });

  final DashboardPageData data;

  @override
  ConsumerState<TeacherAttendanceContainer> createState() =>
      _TeacherAttendanceContainerState();
}

class _TeacherAttendanceContainerState
    extends ConsumerState<TeacherAttendanceContainer> {
  bool _isMarking = false;
  bool _requiresBiometric = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBiometricSupport());
  }

  Future<void> _loadBiometricSupport() async {
    final supported = await ref
        .read(teacherAttendanceFingerprintServiceProvider)
        .canUseBiometrics();
    if (mounted) setState(() => _requiresBiometric = supported);
  }

  void _refreshTeacherAttendance() {
    ref.invalidate(teacherAttendanceStatusProvider);
    ref.invalidate(mosqueProximityProvider);
  }

  void _refreshMosqueProximity() {
    ref.invalidate(mosqueProximityProvider);
  }

  Future<void> _openScreenAndRefreshProximity(Widget screen) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
    if (mounted) _refreshMosqueProximity();
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : null,
      ),
    );
  }

  Future<void> _markTeacherAttendance({String? reEnrollmentPassword}) async {
    setState(() => _isMarking = true);
    try {
      final message = await ref
          .read(teacherAttendanceRepositoryProvider)
          .markAttendance(reEnrollmentPassword: reEnrollmentPassword);
      _refreshTeacherAttendance();
      _showSnack(message);
    } on TeacherAttendanceDeviceReEnrollmentRequired {
      if (mounted) setState(() => _isMarking = false);
      final password = await showDeviceReEnrollmentDialog(context);
      if (password != null && mounted) {
        await _markTeacherAttendance(reEnrollmentPassword: password);
      }
      return;
    } on TeacherAttendanceFingerprintCanceled {
      // User dismissed the biometric prompt.
    } on TeacherAttendanceFingerprintException catch (e) {
      _showSnack(e.message, isError: true);
    } on LocationServiceException catch (e) {
      _showSnack(e.message, isError: true);
    } on ApiException catch (e) {
      _showSnack(e.message, isError: true);
    } catch (_) {
      _showSnack('تعذر تسجيل الحضور', isError: true);
    } finally {
      if (mounted) setState(() => _isMarking = false);
    }
  }

  Future<void> _markTeacherDeparture({String? reEnrollmentPassword}) async {
    setState(() => _isMarking = true);
    try {
      final message = await ref
          .read(teacherAttendanceRepositoryProvider)
          .markDeparture(reEnrollmentPassword: reEnrollmentPassword);
      _refreshTeacherAttendance();
      _showSnack(message);
    } on TeacherAttendanceDeviceReEnrollmentRequired {
      if (mounted) setState(() => _isMarking = false);
      final password = await showDeviceReEnrollmentDialog(context);
      if (password != null && mounted) {
        await _markTeacherDeparture(reEnrollmentPassword: password);
      }
      return;
    } on TeacherAttendanceFingerprintCanceled {
      // User dismissed the biometric prompt.
    } on TeacherAttendanceFingerprintException catch (e) {
      _showSnack(e.message, isError: true);
    } on LocationServiceException catch (e) {
      _showSnack(e.message, isError: true);
    } on ApiException catch (e) {
      _showSnack(e.message, isError: true);
    } catch (_) {
      _showSnack('تعذر تسجيل الانصراف', isError: true);
    } finally {
      if (mounted) setState(() => _isMarking = false);
    }
  }

  Future<void> _onFingerprintAction(TeacherAttendanceStatus status) async {
    if (status.canMarkDeparture) {
      await _markTeacherDeparture();
    } else if (status.canMarkAttendance) {
      await _markTeacherAttendance();
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendanceAsync = ref.watch(teacherAttendanceStatusProvider);
    final proximityAsync = ref.watch(mosqueProximityProvider);
    final data = widget.data;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'مرحباً بك، ${data.teacherName}',
                  style: AppFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.history_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                      onPressed: () {
                        _openScreenAndRefreshProximity(
                          const TeacherAttendanceLogScreen(),
                        );
                      },
                      tooltip: 'سجل الحضور والانصراف',
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.video_call_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                      onPressed: () {
                        _openScreenAndRefreshProximity(const MeetingsScreen());
                      },
                      tooltip: 'الاجتماعات',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            data.circleName.isNotEmpty ? data.circleName : 'معلم الحلقة',
            style: AppFonts.cairo(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primaryLight,
                child: Icon(Icons.person, size: 30, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: attendanceAsync.when(
                  data: (status) => _buildAttendanceStatusChip(status),
                  loading: () => Text(
                    'جاري تحميل حالة الحضور...',
                    style: AppFonts.cairo(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  error: (_, __) => TextButton(
                    onPressed: _refreshTeacherAttendance,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      alignment: AlignmentDirectional.centerStart,
                    ),
                    child: Text(
                      'إعادة تحميل حالة الحضور',
                      style: AppFonts.cairo(
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
              _buildTeacherAttendanceActions(attendanceAsync),
            ],
          ),
          attendanceAsync.when(
            data: (status) => _buildTodayTimesSummary(status),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          proximityAsync.when(
            data: (proximity) => MosqueProximityBanner(proximity: proximity),
            loading: () => Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'جاري تحديد المسافة عن المسجد...',
                    style: AppFonts.cairo(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            error: (error, _) {
              final message = error is LocationServiceException
                  ? error.message
                  : error is ApiException
                      ? error.message
                      : 'تعذر تحديد المسافة عن المسجد';
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_disabled,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message,
                        style: AppFonts.cairo(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: _refreshMosqueProximity,
                      tooltip: 'إعادة المحاولة',
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTodayTimesSummary(TeacherAttendanceStatus status) {
    if (status.isNotAttended) return const SizedBox.shrink();

    final attendance = _parseDateTime(status.attendanceTime);
    if (attendance == null) return const SizedBox.shrink();

    final departure = _parseDateTime(status.departureTime);
    final durationEnd = departure ?? DateTime.now();
    final duration = durationEnd.difference(attendance);
    final durationLabel = status.isDeparted
        ? TeacherAttendanceDuration.format(duration)
        : '${TeacherAttendanceDuration.format(duration)} (جاري)';

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildTodayTimeTile(
                label: 'الحضور',
                value: _formatClockTime(attendance),
                icon: Icons.login_rounded,
                color: AppColors.success,
              ),
            ),
            _buildTodayTimeDivider(),
            Expanded(
              child: _buildTodayTimeTile(
                label: 'الانصراف',
                value: departure != null
                    ? _formatClockTime(departure)
                    : '—',
                icon: Icons.logout_rounded,
                color: status.isDeparted
                    ? AppColors.textSecondary
                    : AppColors.textSecondary.withValues(alpha: 0.5),
              ),
            ),
            _buildTodayTimeDivider(),
            Expanded(
              child: _buildTodayTimeTile(
                label: 'المدة',
                value: durationLabel,
                icon: Icons.timelapse_rounded,
                color: AppColors.primary,
                compact: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayTimeDivider() {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: AppColors.border,
    );
  }

  Widget _buildTodayTimeTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    bool compact = false,
  }) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppFonts.cairo(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: compact ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: AppFonts.cairo(
            fontSize: compact ? 12 : 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  DateTime? _parseDateTime(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  String _formatClockTime(DateTime value) =>
      intl.DateFormat('hh:mm a', 'ar').format(value);

  Widget _buildAttendanceStatusChip(TeacherAttendanceStatus status) {
    final Color color;
    final IconData icon;

    if (status.isDeparted) {
      color = AppColors.textSecondary;
      icon = Icons.logout;
    } else if (status.isVacation) {
      color = AppColors.textSecondary;
      icon = Icons.beach_access_outlined;
    } else if (status.isAttended) {
      color = AppColors.success;
      icon = Icons.check_circle_outline;
    } else {
      color = AppColors.warning;
      icon = Icons.schedule;
    }

    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            status.message,
            style: AppFonts.cairo(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherAttendanceActions(
    AsyncValue<TeacherAttendanceStatus> attendanceAsync,
  ) {
    final status = attendanceAsync.valueOrNull;
    if (status == null) return const SizedBox.shrink();

    final isDeparture = status.canMarkDeparture;
    final isEnabled =
        (status.canMarkAttendance || status.canMarkDeparture) && !_isMarking;

    return _buildTeacherActionIcon(
      icon: _requiresBiometric ? Icons.fingerprint_rounded : Icons.touch_app_rounded,
      tooltip: isDeparture
          ? (_requiresBiometric ? 'تسجيل انصراف بالبصمة' : 'تسجيل الانصراف')
          : status.isDeparted
              ? 'تم تسجيل الحضور والانصراف اليوم'
              : (_requiresBiometric ? 'تسجيل حضور بالبصمة' : 'تسجيل الحضور'),
      color: isDeparture ? AppColors.warning : AppColors.success,
      enabled: isEnabled,
      isLoading: _isMarking,
      onPressed: isEnabled ? () => _onFingerprintAction(status) : null,
    );
  }

  Widget _buildTeacherActionIcon({
    required IconData icon,
    required String tooltip,
    required Color color,
    required bool enabled,
    required bool isLoading,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: enabled && !isLoading ? onPressed : null,
      icon: isLoading
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: color.withValues(alpha: 0.7),
              ),
            )
          : Icon(
              icon,
              color: enabled
                  ? color
                  : AppColors.textSecondary.withValues(alpha: 0.4),
              size: 28,
            ),
    );
  }
}
