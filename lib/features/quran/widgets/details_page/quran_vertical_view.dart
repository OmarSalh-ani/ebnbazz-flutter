import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:masged_parent_app/features/quran/helpers/constants.dart';
import 'package:masged_parent_app/features/quran/helpers/hive_helper.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran/quran.dart'; // For getJuzNumber
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:masged_parent_app/features/quran/widgets/header_widget.dart';
import 'package:masged_parent_app/features/quran/widgets/bismallah.dart';
import 'package:masged_parent_app/features/quran/helpers/convertNumberToAr.dart';
import 'package:masged_parent_app/features/quran/helpers/quran_page_utils.dart';

class QuranVerticalView extends StatefulWidget {
  final ItemScrollController itemScrollController;
  final ItemPositionsListener itemPositionsListener;
  final Function(int) onPageChanged;
  final dynamic jsonData;
  final dynamic quarterJsonData;
  final bool shouldHighlightText;
  final dynamic highlightVerse;

  const QuranVerticalView({
    Key? key,
    required this.itemScrollController,
    required this.itemPositionsListener,
    required this.onPageChanged,
    required this.jsonData,
    required this.quarterJsonData,
    required this.shouldHighlightText,
    required this.highlightVerse,
  }) : super(key: key);

  @override
  State<QuranVerticalView> createState() => _QuranVerticalViewState();
}

class _QuranVerticalViewState extends State<QuranVerticalView> {
  String selectedSpan = "";
  List<GlobalKey> richTextKeys = List.generate(
    604,
    (_) => GlobalKey(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: backgroundColors[getValue("quranPageolorsIndex")],
      body: Stack(
        children: [
          ScrollablePositionedList.separated(
            itemCount: quran.totalPagesCount + 1,
            separatorBuilder: (context, index) {
              if (index == 0) return Container();
              return Container(
                color: secondaryColors[getValue("quranPageolorsIndex")]
                    .withOpacity(.45),
                width: double.infinity,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 77.0.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        QuranPageUtils.checkIfPageIncludesQuarterAndQuarterIndex(
                                        widget.quarterJsonData,
                                        quran.getPageData(index),
                                        indexes)
                                    .includesQuarter ==
                                true
                            ? "صفحة ${(index).toString()} | ${(QuranPageUtils.checkIfPageIncludesQuarterAndQuarterIndex(widget.quarterJsonData, quran.getPageData(index), indexes).quarterIndex + 1) == 1 ? "" : "${(QuranPageUtils.checkIfPageIncludesQuarterAndQuarterIndex(widget.quarterJsonData, quran.getPageData(index), indexes).quarterIndex).toString()}/${4.toString()}"} حزب ${(QuranPageUtils.checkIfPageIncludesQuarterAndQuarterIndex(widget.quarterJsonData, quran.getPageData(index), indexes).hizbIndex + 1).toString()} | جزء: ${getJuzNumber(quran.getPageData(index)[0]["surah"], quran.getPageData(index)[0]["start"])} "
                            : "صفحة $index | جزء: ${getJuzNumber(quran.getPageData(index)[0]["surah"], quran.getPageData(index)[0]["start"])}",
                        style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: backgroundColors[
                                getValue("quranPageolorsIndex")]),
                      ),
                      Text(
                        widget.jsonData[
                                quran.getPageData(index)[0]["surah"] - 1]
                            ["name"],
                        style: TextStyle(
                            fontSize: 12.sp,
                            fontFamily: "taha",
                            fontWeight: FontWeight.bold,
                            color: backgroundColors[
                                getValue("quranPageolorsIndex")]),
                      )
                    ],
                  ),
                ),
              );
            },
            itemScrollController: widget.itemScrollController,
            initialScrollIndex: getValue("lastRead"),
            itemPositionsListener: widget.itemPositionsListener,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Container(
                  color: const Color(0xffFFFCE7),
                  child: Image.asset(
                    "assets/images/quran.jpg",
                    fit: BoxFit.fill,
                  ),
                );
              }

              return VisibilityDetector(
                      key: Key(index.toString()),
                      onVisibilityChanged: (VisibilityInfo info) {
                        if (info.visibleFraction == 1) {
                          widget.onPageChanged(index);
                        }
                      },
                      child: Column(
                        children: [
                          Directionality(
                            textDirection: m.TextDirection.rtl,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20.0.w, vertical: 26.h),
                              child: SizedBox(
                                  width: double.infinity,
                                  child: RichText(
                                    key: richTextKeys[index - 1],
                                    textDirection: m.TextDirection.rtl,
                                    textAlign: TextAlign.center,
                                    softWrap: true,
                                    text: TextSpan(
                                      locale: const Locale("ar"),
                                      children: quran
                                          .getPageData(index)
                                          .expand((e) {
                                        List<InlineSpan> spans = [];
                                        for (var i = e["start"];
                                            i <= e["end"];
                                            i++) {
                                          // Header
                                          if (i == 1) {
                                            spans.add(WidgetSpan(
                                              child: HeaderWidget(
                                                  e: e,
                                                  jsonData: widget.jsonData),
                                            ));

                                            if (index != 187 && index != 1) {
                                              spans.add(WidgetSpan(
                                                  child: Basmallah(
                                                index: getValue(
                                                    "quranPageolorsIndex"),
                                              )));
                                            }
                                            if (index == 187 || index == 1) {
                                              spans.add(WidgetSpan(
                                                  child: Container(
                                                height: 10.h,
                                              )));
                                            }
                                          }

                                          // Verses
                                          spans.add(TextSpan(
                                            locale: const Locale("ar"),
                                            recognizer:
                                                LongPressGestureRecognizer()
                                                  ..onLongPressDown =
                                                      (details) {
                                                    setState(() {
                                                      selectedSpan =
                                                          " ${e["surah"]}$i";
                                                    });
                                                  }
                                                  ..onLongPressUp = () {
                                                    setState(() {
                                                      selectedSpan = "";
                                                    });
                                                  }
                                                  ..onLongPressCancel =
                                                      () => setState(() {
                                                            selectedSpan = "";
                                                          }),
                                            text: quran.getVerse(
                                                e["surah"], i),
                                            style: TextStyle(
                                              color: primaryColors[getValue(
                                                  "quranPageolorsIndex")],
                                              fontSize: getValue(
                                                      "verticalViewFontSize")
                                                  .toDouble(),
                                              fontFamily: getValue(
                                                  "selectedFontFamily"),
                                              backgroundColor: widget.shouldHighlightText
                                                  ? quran.getVerse(e["surah"], i) == widget.highlightVerse
                                                      ? highlightColors[getValue("quranPageolorsIndex")].withOpacity(.25)
                                                      : selectedSpan == " ${e["surah"]}$i"
                                                          ? highlightColors[getValue("quranPageolorsIndex")].withOpacity(.25)
                                                          : Colors.transparent
                                                  : selectedSpan == " ${e["surah"]}$i"
                                                      ? highlightColors[getValue("quranPageolorsIndex")].withOpacity(.25)
                                                      : Colors.transparent,
                                            ),
                                            children: [
                                              TextSpan(
                                                  text:
                                                      " ${convertToArabicNumber((i).toString())} ",
                                                  style: TextStyle(
                                                      color:
                                                          secondaryColors[
                                                              getValue(
                                                                  "quranPageolorsIndex")],
                                                      fontFamily:
                                                          "KFGQPC Uthmanic Script HAFS Regular")),
                                            ],
                                          ));
                                        }
                                        return spans;
                                      }).toList(),
                                    ),
                                  )),
                            ),
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
}
