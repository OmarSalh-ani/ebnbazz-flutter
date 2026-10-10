import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart' as quran;

import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../models/child_model.dart';
import '../models/student_quran_assignment.dart';
import '../services/students_api_service.dart';

/// Shows the teacher-assigned memorize (and revise) verses for this student.
class QuranScreen extends StatefulWidget {
  final ChildModel child;

  const QuranScreen({super.key, required this.child});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  final _api = StudentsApiService();
  StudentQuranAssignment? _assignment;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final a = await _api.getQuranAssignment(widget.child.id);
      if (mounted) {
        setState(() {
          _assignment = a;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is ApiException ? e.message : 'تعذر تحميل الخطة';
          _loading = false;
        });
      }
    }
  }

  String _assignmentTitle(StudentQuranAssignment a) {
    final memo = (a.memorizeSurahNameArabic).trim().isEmpty
        ? quran.getSurahNameArabic(a.memorizeSurahId)
        : a.memorizeSurahNameArabic;
    return '$memo (آيات ${a.memorizeFromAyah}–${a.memorizeToAyah})';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'تسميع القرآن',
          style: AppFonts.cairo(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error.toString(),
                          textAlign: TextAlign.center,
                          style: AppFonts.cairo(color: AppColors.error),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _load,
                          child: Text('إعادة المحاولة', style: AppFonts.cairo()),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildChildHeader(widget.child, _assignment!),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _surahSection(
                              title: 'الحفظ',
                              subtitle: _assignmentTitle(_assignment!),
                              surahId: _assignment!.memorizeSurahId,
                              fromAyah: _assignment!.memorizeFromAyah,
                              toAyah: _assignment!.memorizeToAyah,
                            ),
                            if (_assignment!.hasRevise) ...[
                              const SizedBox(height: 20),
                              _surahSection(
                                title: 'المراجعة',
                                subtitle:
                                    '${(_assignment!.reviseSurahNameArabic ?? '').trim().isEmpty ? quran.getSurahNameArabic(_assignment!.reviseSurahId!) : _assignment!.reviseSurahNameArabic} '
                                    '(آيات ${_assignment!.reviseFromAyah}–${_assignment!.reviseToAyah})',
                                surahId: _assignment!.reviseSurahId!,
                                fromAyah: _assignment!.reviseFromAyah,
                                toAyah: _assignment!.reviseToAyah,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildChildHeader(ChildModel child, StudentQuranAssignment a) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'الخطة من المعلم',
              style: AppFonts.cairo(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _assignmentTitle(a),
              textAlign: TextAlign.center,
              style: AppFonts.cairo(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    child.name,
                    style: AppFonts.cairo(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn().scale(delay: 100.ms),
    );
  }

  Widget _surahSection({
    required String title,
    required String subtitle,
    required int surahId,
    required int fromAyah,
    required int toAyah,
  }) {
    final maxV = quran.getVerseCount(surahId);
    final safeFrom = fromAyah.clamp(1, maxV);
    final safeTo = toAyah.clamp(safeFrom, maxV);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 24),
          _buildSurahHeader(surahId),
          const Divider(height: 1),
          _buildVerseRange(surahId, safeFrom, safeTo),
        ],
      ),
    );
  }

  Widget _buildSurahHeader(int surahNumber) {
    final showBasmala = surahNumber != 1 && surahNumber != 9;
    return Container(
      padding: const EdgeInsets.all(28),
      width: double.infinity,
      child: Column(
        children: [
          Text(
            quran.getSurahNameArabic(surahNumber),
            style: GoogleFonts.amiri(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          if (showBasmala) ...[
            const SizedBox(height: 16),
            Text(
              quran.basmala,
              style: GoogleFonts.amiri(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVerseRange(int surahNumber, int from, int to) {
    final count = to - from + 1;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      itemCount: count,
      separatorBuilder: (context, index) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Divider(color: AppColors.border),
      ),
      itemBuilder: (context, index) {
        final verseNumber = from + index;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                verseNumber.toString(),
                style: AppFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                quran.getVerse(surahNumber, verseNumber),
                style: GoogleFonts.amiri(
                  fontSize: 22,
                  height: 1.8,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
              ),
            ),
          ],
        );
      },
    );
  }
}
