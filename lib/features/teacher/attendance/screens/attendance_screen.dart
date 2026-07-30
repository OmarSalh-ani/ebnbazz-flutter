import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:masged_parent_app/teacher_core/network/api_exception.dart';
import 'package:masged_parent_app/teacher_core/services/location_service.dart';
import 'package:masged_parent_app/core/theme/app_colors.dart';
import '../../dashboard/models/dashboard_models.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../providers/attendance_providers.dart';
import '../data/attendance_api.dart';

class _QrScanRecord {
  const _QrScanRecord({
    required this.student,
    required this.message,
  });

  final StudentListItem student;
  final String message;
}

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isAttendanceMode = true;
  final Map<int, String> _manualStatus = {};
  Map<int, String> _initialAttendanceStatus = {};
  Map<int, String> _initialDepartureStatus = {};
  bool _isSaving = false;
  String _lastStudentsSignature = '';

  final _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  bool _isQrTabActive = false;
  bool _isScanProcessing = false;
  final List<_QrScanRecord> _scanHistory = [];
  String? _lastScannedCode;
  DateTime? _lastScanAt;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final onQrTab = _tabController.index == 1;
    if (onQrTab == _isQrTabActive) return;
    // MobileScanner starts/stops via widget mount when autoStart is true.
    setState(() => _isQrTabActive = onQrTab);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _initStatusMaps(List<StudentListItem> students) {
    _initialAttendanceStatus = {
      for (final s in students) s.id: s.isPresentToday,
    };
    _initialDepartureStatus = {
      for (final s in students) s.id: s.departureStatusToday,
    };

    for (final student in students) {
      if (_isAttendanceMode) {
        _manualStatus[student.id] =
            (student.isPresentToday == 'حاضر' || student.isPresentToday == 'منصرف')
                ? 'حاضر'
                : 'غائب';
      } else {
        _manualStatus[student.id] = student.hasDepartedToday
            ? 'منصرف'
            : 'لم ينصرف';
      }
    }
  }

  void _onModeChanged(bool attendanceMode, List<StudentListItem> students) {
    setState(() {
      _isAttendanceMode = attendanceMode;
      for (final student in students) {
        if (_isAttendanceMode) {
          _manualStatus[student.id] =
              (student.isPresentToday == 'حاضر' ||
                      student.isPresentToday == 'منصرف')
                  ? 'حاضر'
                  : 'غائب';
        } else {
          _manualStatus[student.id] =
              student.hasDepartedToday ? 'منصرف' : 'لم ينصرف';
        }
      }
    });
  }

  Future<void> _saveChanges(List<StudentListItem> students) async {
    setState(() => _isSaving = true);
    try {
      final controller = ref.read(attendanceControllerProvider);
      final message = await controller.saveChanges(
        isAttendanceMode: _isAttendanceMode,
        students: students,
        manualStatus: _manualStatus,
        initialAttendanceStatus: _initialAttendanceStatus,
        initialDepartureStatus: _initialDepartureStatus,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

      controller.refreshAfterChange();
    } on LocationServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر حفظ التغييرات'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  StudentListItem _studentForScanResult(
    ScanQrResult result,
    List<StudentListItem> students,
  ) {
    for (final student in students) {
      if (student.id == result.studentId) return student;
    }

    return StudentListItem(
      id: result.studentId,
      name: result.studentName,
      age: 0,
      group: '',
      planLevelName: '',
      isPresentToday: '',
      departureStatusToday: '',
      departureTimeToday: '',
      fatherPhone: '',
    );
  }

  void _onQrDetected(BarcodeCapture capture, List<StudentListItem> students) {
    if (!_isQrTabActive || _isScanProcessing) return;

    final barcode = capture.barcodes
        .where((b) => b.rawValue != null && b.rawValue!.trim().isNotEmpty)
        .map((b) => b.rawValue!)
        .firstOrNull;
    if (barcode == null) return;

    final now = DateTime.now();
    if (_lastScannedCode == barcode &&
        _lastScanAt != null &&
        now.difference(_lastScanAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastScannedCode = barcode;
    _lastScanAt = now;

    _processQrCode(barcode, students);
  }

  Future<void> _processQrCode(String raw, List<StudentListItem> students) async {
    final qrToken = raw.trim();
    if (qrToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رمز QR غير صالح')),
      );
      return;
    }

    setState(() => _isScanProcessing = true);

    try {
      final controller = ref.read(attendanceControllerProvider);
      final result = await controller.scanQr(
        isAttendanceMode: _isAttendanceMode,
        qrToken: qrToken,
      );

      if (!mounted) return;
      setState(() {
        _scanHistory.insert(
          0,
          _QrScanRecord(
            student: _studentForScanResult(result, students),
            message: result.message,
          ),
        );
      });
      controller.refreshAfterChange();
    } on LocationServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isScanProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(attendanceStudentsProvider);
    final isWorkDayToday =
        ref.watch(dashboardPageProvider).valueOrNull?.isWorkDayToday ?? true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'تسجيل الحضور والانصراف',
          style: AppFonts.cairo(fontWeight: FontWeight.bold),
        ),
        actions: [
          studentsAsync.maybeWhen(
            data: (students) {
              if (students.isEmpty) return const SizedBox.shrink();
              final canSave = isWorkDayToday && !_isSaving;
              return TextButton(
                onPressed: canSave ? () => _saveChanges(students) : null,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'حفظ',
                        style: AppFonts.cairo(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelStyle: AppFonts.cairo(fontWeight: FontWeight.bold),
          unselectedLabelStyle: AppFonts.cairo(),
          tabs: const [
            Tab(text: 'تسجيل يدوي'),
            Tab(text: 'مسح QR'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (!isWorkDayToday)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.textSecondary.withValues(alpha: 0.12),
              child: Text(
                'اليوم إجازة — لا يمكن تسجيل الحضور أو الانصراف',
                textAlign: TextAlign.center,
                style: AppFonts.cairo(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          Expanded(
            child: studentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _buildErrorState(error),
              data: (students) {
                final signature = students
                    .map((s) =>
                        '${s.id}:${s.isPresentToday}:${s.departureStatusToday}')
                    .join('|');
                if (signature != _lastStudentsSignature) {
                  _lastStudentsSignature = signature;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _initStatusMaps(students));
                  });
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildManualTab(students, isWorkDayToday: isWorkDayToday),
                    _buildQrTab(students, isWorkDayToday: isWorkDayToday),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    final message =
        error is ApiException ? error.message : 'تعذر تحميل قائمة الطلاب';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: AppFonts.cairo()),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(attendanceStudentsProvider),
              child: Text('إعادة المحاولة', style: AppFonts.cairo()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualTab(List<StudentListItem> students, {required bool isWorkDayToday}) {
    if (students.isEmpty) {
      return Center(
        child: Text(
          'لا يوجد طلاب في الحلقة',
          style: AppFonts.cairo(color: AppColors.textSecondary),
        ),
      );
    }

    return AbsorbPointer(
      absorbing: !isWorkDayToday,
      child: Opacity(
        opacity: isWorkDayToday ? 1 : 0.5,
        child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildModeBtn('تحضير الحضور', _isAttendanceMode, () {
                    _onModeChanged(true, students);
                  }),
                ),
                Expanded(
                  child: _buildModeBtn('تحضير الانصراف', !_isAttendanceMode, () {
                    _onModeChanged(false, students);
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'قائمة الطلاب (${students.length})',
            style: AppFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: students.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _buildManualStudentCard(students[index]),
          ),
        ],
      ),
        ),
      ),
    );
  }

  Widget _buildModeBtn(String title, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: AppFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildManualStudentCard(StudentListItem student) {
    final currentStatus = _manualStatus[student.id];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStudentAvatar(student, radius: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: AppFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  student.group,
                  style: AppFonts.cairo(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: _isAttendanceMode
                ? [
                    _buildStatusOption('حاضر', currentStatus == 'حاضر',
                        AppColors.success, () {
                      setState(() => _manualStatus[student.id] = 'حاضر');
                    }),
                    const SizedBox(width: 8),
                    _buildStatusOption('غائب', currentStatus == 'غائب',
                        AppColors.error, () {
                      setState(() => _manualStatus[student.id] = 'غائب');
                    }),
                  ]
                : [
                    _buildStatusOption('منصرف', currentStatus == 'منصرف',
                        AppColors.warning, () {
                      setState(() => _manualStatus[student.id] = 'منصرف');
                    }),
                    const SizedBox(width: 8),
                    _buildStatusOption(
                      'لم ينصرف',
                      currentStatus == 'لم ينصرف',
                      AppColors.textHint,
                      () {
                        setState(() => _manualStatus[student.id] = 'لم ينصرف');
                      },
                    ),
                  ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOption(
    String title,
    bool isSelected,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          border: Border.all(color: isSelected ? color : AppColors.inputBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: AppFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildStudentAvatar(StudentListItem student, {required double radius}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryLight,
      backgroundImage:
          student.imageUrl != null ? NetworkImage(student.imageUrl!) : null,
      child: student.imageUrl == null
          ? Icon(Icons.person, color: AppColors.primary, size: radius)
          : null,
    );
  }

  Widget _buildQrTab(List<StudentListItem> students, {required bool isWorkDayToday}) {
    return AbsorbPointer(
      absorbing: !isWorkDayToday,
      child: Opacity(
        opacity: isWorkDayToday ? 1 : 0.5,
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: _buildModeBtn('حضور', _isAttendanceMode, () {
                  setState(() => _isAttendanceMode = true);
                }),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildModeBtn('انصراف', !_isAttendanceMode, () {
                  setState(() => _isAttendanceMode = false);
                }),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            _isAttendanceMode
                ? 'وجّه الكاميرا نحو بطاقة الطالب لتسجيل الحضور'
                : 'وجّه الكاميرا نحو بطاقة الطالب لتسجيل الانصراف',
            textAlign: TextAlign.center,
            style: AppFonts.cairo(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_isQrTabActive)
                    MobileScanner(
                      controller: _scannerController,
                      onDetect: (capture) => _onQrDetected(capture, students),
                    )
                  else
                    ColoredBox(
                      color: Colors.black87,
                      child: Icon(
                        Icons.qr_code_scanner,
                        size: 72,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  if (_isScanProcessing)
                    Container(
                      color: Colors.black45,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                  if (!kIsWeb)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        onPressed: () => _scannerController.toggleTorch(),
                        icon: ValueListenableBuilder(
                          valueListenable: _scannerController,
                          builder: (context, state, _) {
                            final on = state.torchState == TorchState.on;
                            return Icon(
                              on ? Icons.flash_on : Icons.flash_off,
                              color: Colors.white,
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (kIsWeb)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'على المتصفح قد تحتاج السماح باستخدام الكاميرا عند الطلب',
              textAlign: TextAlign.center,
              style: AppFonts.cairo(
                fontSize: 11,
                color: AppColors.textHint,
              ),
            ),
          ),
        Expanded(
          flex: 3,
          child: _scanHistory.isEmpty
              ? Center(
                  child: Text(
                    'سيظهر هنا اسم وصورة كل طالب بعد المسح',
                    style: AppFonts.cairo(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _scanHistory.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _buildScanResultCard(_scanHistory[index]),
                ),
        ),
      ],
        ),
      ),
    );
  }

  Widget _buildScanResultCard(_QrScanRecord record) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStudentAvatar(record.student, radius: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.student.name,
                  style: AppFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  record.student.group,
                  style: AppFonts.cairo(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  record.message,
                  style: AppFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: AppColors.success, size: 26),
        ],
      ),
    );
  }
}
