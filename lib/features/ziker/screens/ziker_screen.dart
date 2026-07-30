import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';

class ZikerScreen extends StatefulWidget {
  final String zikerName;
  const ZikerScreen({super.key, required this.zikerName});

  @override
  State<ZikerScreen> createState() => _ZikerScreenState();
}

class _ZikerScreenState extends State<ZikerScreen> {
  static const int _defaultCircleTarget = 33;
  static const int _minCircleTarget = 10;
  static const int _maxCircleTarget = 100;
  static const String _circleTargetKey = 'ziker_circle_target';

  int _sessionCounter = 0;
  int _lifetimeCounter = 0;
  int _circleTarget = _defaultCircleTarget;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lifetimeCounter = prefs.getInt('ziker_counter_${widget.zikerName}') ?? 0;
      _circleTarget = prefs.getInt(_circleTargetKey) ?? _defaultCircleTarget;
    });
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    // Save to SharedPreferences (Lifetime)
    int newTotal = (prefs.getInt('ziker_counter_${widget.zikerName}') ?? 0) + 1;
    await prefs.setInt('ziker_counter_${widget.zikerName}', newTotal);
    setState(() {
      _lifetimeCounter = newTotal;
    });
  }

  void _incrementCounter() {
    HapticFeedback.lightImpact();
    setState(() {
      _sessionCounter++;
    });
    _saveProgress();
  }

  void _resetSessionCounter() {
    // Return session count to 0 in UI, but don't delete lifetime data in SharedPreferences
    setState(() {
      _sessionCounter = 0;
    });
  }

  Future<void> _saveCircleTarget(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_circleTargetKey, value);
    setState(() {
      _circleTarget = value;
    });
  }

  void _showCircleTargetSheet() {
    int tempTarget = _circleTarget;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'عدد التسبيحات في الدورة',
                    textAlign: TextAlign.center,
                    style: AppFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$tempTarget',
                    textAlign: TextAlign.center,
                    style: AppFonts.cairo(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Slider(
                    value: tempTarget.toDouble(),
                    min: _minCircleTarget.toDouble(),
                    max: _maxCircleTarget.toDouble(),
                    divisions: _maxCircleTarget - _minCircleTarget,
                    activeColor: AppColors.primary,
                    label: tempTarget.toString(),
                    onChanged: (value) {
                      setSheetState(() {
                        tempTarget = value.round();
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$_minCircleTarget',
                        style: AppFonts.cairo(color: AppColors.textHint, fontSize: 14),
                      ),
                      Text(
                        '$_maxCircleTarget',
                        style: AppFonts.cairo(color: AppColors.textHint, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      _saveCircleTarget(tempTarget);
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      'حفظ',
                      style: AppFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  double get _circleProgress {
    if (_sessionCounter == 0) return 0;
    final cycleCount = _sessionCounter % _circleTarget;
    return cycleCount == 0 ? 1.0 : cycleCount / _circleTarget;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          title: Text(
            widget.zikerName,
            style: AppFonts.cairo(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.tune_rounded, color: AppColors.primary),
              onPressed: _showCircleTargetSheet,
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
              onPressed: _resetSessionCounter,
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              // Session Total Display (Now at the top)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: AppColors.gold, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'الأجمالي:',
                        style: AppFonts.cairo(fontSize: 16, color: AppColors.textSecondary),
                      ),
                      const Spacer(),
                      Text(
                        _sessionCounter.toString(),
                        style: AppFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn().slideY(begin: -0.1),
              
              const Spacer(),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  widget.zikerName,
                  textAlign: TextAlign.center,
                  style: AppFonts.cairo(
                    fontSize: 22,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Counter Display (Bigger Circle)
              GestureDetector(
                onTap: _incrementCounter,
                child: Container(
                  width: 320, // Increased size
                  height: 320, // Increased size
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 40,
                        spreadRadius: 8,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer Ring (Scaled up)
                      SizedBox(
                        width: 290,
                        height: 290,
                        child: CircularProgressIndicator(
                          value: _circleProgress,
                          strokeWidth: 10,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _sessionCounter.toString(),
                            style: AppFonts.cairo(
                              fontSize: 80,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'تسبيحة',
                            style: AppFonts.cairo(
                              fontSize: 18,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate(target: _sessionCounter.toDouble()).scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.05, 1.05),
                  duration: 100.ms,
                  curve: Curves.easeOut,
                ).then().scale(
                  begin: const Offset(1.05, 1.05),
                  end: const Offset(1.0, 1.0),
                  duration: 100.ms,
                ),
              ),
              
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _showCircleTargetSheet,
                child: Text(
                  'الدورة: $_circleTarget تسبيحة',
                  style: AppFonts.cairo(
                    color: AppColors.textHint,
                    fontSize: 14,
                  ),
                ),
              ),

              const Spacer(),

              // Lifetime Info
              Text(
                'الإجمالي الكلي: $_lifetimeCounter',
                style: AppFonts.cairo(color: AppColors.textHint, fontSize: 14),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                child: Text(
                  'اضغط على الدائرة للتسبيح',
                  style: AppFonts.cairo(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
