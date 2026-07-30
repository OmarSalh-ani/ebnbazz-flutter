import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quran/quran.dart' as quran;
import 'package:masged_parent_app/features/quran/helpers/constants.dart';
import 'package:masged_parent_app/features/quran/helpers/hive_helper.dart';
import 'package:masged_parent_app/features/quran/helpers/convertNumberToAr.dart';
import 'package:masged_parent_app/features/quran/widgets/bismallah.dart';

class SurahDetailScreen extends StatefulWidget {
  final int surahNumber;
  final int? initialVerse;
  const SurahDetailScreen({super.key, required this.surahNumber, this.initialVerse});

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  final ScrollController _scrollController = ScrollController();

  int get _colorIndex => (getValue("quranPageolorsIndex") ?? 0) as int;
  String get _fontFamily =>
      (getValue("selectedFontFamily") ?? "UthmanicHafs13") as String;
  double get _fontSize =>
      ((getValue("verseByVerseFontSize") ?? 22) as num).toDouble();

  @override
  void initState() {
    super.initState();
    if (widget.initialVerse != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final approxOffset = (widget.initialVerse! - 1) * 120.0;
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            approxOffset,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final verseCount = quran.getVerseCount(widget.surahNumber);
    final bgColor = backgroundColors[_colorIndex] as Color;
    final primaryColor = primaryColors[_colorIndex] as Color;
    final secondaryColor = secondaryColors[_colorIndex] as Color;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          title: Text(
            quran.getSurahNameArabic(widget.surahNumber),
            style: TextStyle(
              fontFamily: _fontFamily,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryColor),
            onPressed: () => context.pop(),
          ),
        ),
        body: Column(
          children: [
            if (widget.surahNumber != 1 && widget.surahNumber != 9)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Basmallah(index: _colorIndex),
              ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                itemCount: verseCount,
                itemBuilder: (context, index) {
                  final verseNumber = index + 1;
                  final verseText = quran.getVerse(
                    widget.surahNumber,
                    verseNumber,
                    verseEndSymbol: false,
                  );
                  final arabicVerseNum =
                      convertToArabicNumber(verseNumber.toString());

                  return Padding(
                    padding: EdgeInsets.only(bottom: 20.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: secondaryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              arabicVerseNum,
                              style: TextStyle(
                                fontFamily:
                                    "KFGQPC Uthmanic Script HAFS Regular",
                                fontSize: 14.sp,
                                color: secondaryColor,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Directionality(
                          textDirection: m.TextDirection.rtl,
                          child: RichText(
                            textDirection: m.TextDirection.rtl,
                            textAlign: TextAlign.center,
                            softWrap: true,
                            locale: const Locale("ar"),
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: verseText,
                                  style: TextStyle(
                                    fontFamily: _fontFamily,
                                    fontSize: _fontSize.sp,
                                    color: primaryColor,
                                    height: 1.95.h,
                                    letterSpacing: 0,
                                    wordSpacing: 0,
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      " \u06DD$arabicVerseNum\u06DD ",
                                  style: TextStyle(
                                    fontFamily:
                                        "KFGQPC Uthmanic Script HAFS Regular",
                                    fontSize: 20.sp,
                                    color: secondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Divider(
                          color: primaryColor.withValues(alpha: 0.15),
                          thickness: 0.8,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
