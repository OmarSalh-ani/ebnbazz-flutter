import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:masged_parent_app/features/quran/helpers/constants.dart';
import 'package:masged_parent_app/features/quran/helpers/hive_helper.dart';
import 'package:masged_parent_app/features/quran/helpers/qcf_font_loader.dart';
import 'package:quran/quran.dart' as quran;
import 'package:masged_parent_app/features/quran/widgets/header_widget.dart';
import 'package:masged_parent_app/features/quran/widgets/bismallah.dart';
import 'package:masged_parent_app/features/quran/widgets/details_page/quran_page_header.dart';
class QuranPageView extends StatefulWidget {
  final PageController pageController;
  final Function(int) onPageChanged;
  final Function() onBack;
  final Function() onSettings;
  final dynamic jsonData;
  final dynamic quarterJsonData;
  final bool shouldHighlightText;
  final dynamic highlightVerse;
  final int index;

  const QuranPageView({
    Key? key,
    required this.pageController,
    required this.onPageChanged,
    required this.onBack,
    required this.onSettings,
    required this.jsonData,
    required this.quarterJsonData,
    required this.shouldHighlightText,
    required this.highlightVerse,
    required this.index,
  }) : super(key: key);

  @override
  State<QuranPageView> createState() => _QuranPageViewState();
}

class _QuranPageViewState extends State<QuranPageView> {
  String selectedSpan = "";
  List<GlobalKey> richTextKeys = List.generate(
    604,
    (_) => GlobalKey(),
  );

  void _preloadNearbyQcfFonts(int pageIndex) {
    if (pageIndex < 1) return;
    unawaited(
      QcfFontLoader.ensurePagesLoaded([
        pageIndex - 1,
        pageIndex,
        pageIndex + 1,
      ].where((page) => page >= 1 && page <= quran.totalPagesCount)),
    );
  }

  @override
  void initState() {
    super.initState();
    widget.pageController.addListener(_pageControllerScrollListener);
    _preloadNearbyQcfFonts(widget.index);
  }

  void _pageControllerScrollListener() {
    if (widget.pageController.position.isScrollingNotifier.value &&
        selectedSpan != "") {
      setState(() {
        selectedSpan = "";
      });
    }
  }

  @override
  void dispose() {
    widget.pageController.removeListener(_pageControllerScrollListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      scrollBehavior: const m.MaterialScrollBehavior().copyWith(
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
      ),
      scrollDirection: Axis.horizontal,
      onPageChanged: (a) {
        setState(() {
          selectedSpan = "";
        });
        _preloadNearbyQcfFonts(a);
        widget.onPageChanged(a);
      },
      controller: widget.pageController,
      reverse: false,
      itemCount: quran.totalPagesCount + 1,
      itemBuilder: (context, index) {
        bool isEvenPage = index.isEven;

        if (index == 0) {
          return Container(
            color: const Color(0xffFFFCE7),
            child: Image.asset(
              "assets/images/quran.jpg",
              fit: BoxFit.fill,
            ),
          );
        }

        return FutureBuilder<void>(
          future: QcfFontLoader.ensurePageLoaded(index),
          builder: (context, fontSnapshot) {
            if (fontSnapshot.connectionState != ConnectionState.done) {
              return ColoredBox(
                color: backgroundColors[getValue("quranPageolorsIndex")],
                child: const Center(child: CircularProgressIndicator()),
              );
            }
            if (fontSnapshot.hasError) {
              return ColoredBox(
                color: backgroundColors[getValue("quranPageolorsIndex")],
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'تعذر تحميل خط الصفحة. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: primaryColors[getValue("quranPageolorsIndex")],
                        fontFamily: 'cairo',
                      ),
                    ),
                  ),
                ),
              );
            }

            return Container(
          decoration: BoxDecoration(
              color: backgroundColors[getValue("quranPageolorsIndex")],
              boxShadow: [
                if (isEvenPage)
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 5,
                    blurRadius: 10,
                    offset: const Offset(-5, 0),
                  ),
              ],
              border: Border.fromBorderSide(BorderSide(
                  color: primaryColors[getValue("quranPageolorsIndex")]
                      .withOpacity(.05)))),
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(right: 12.0.w, left: 12.w),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      QuranPageHeader(
                        index: index,
                        jsonData: widget.jsonData,
                        quarterJsonData: widget.quarterJsonData,
                        onBack: widget.onBack,
                        onSettings: widget.onSettings,
                      ),
                      Directionality(
                          textDirection: m.TextDirection.rtl,
                          child: Padding(
                            padding: const EdgeInsets.all(0.0),
                            child: SizedBox(
                              width: double.infinity,
                              child: RichText(
                                key: richTextKeys[index - 1],
                                textDirection: m.TextDirection.rtl,
                                textAlign: TextAlign.center,
                                softWrap: true,
                                locale: const Locale("ar"),
                                text: TextSpan(
                                  style: TextStyle(
                                    color: primaryColors[getValue(
                                        "quranPageolorsIndex")],
                                    fontSize: getValue(
                                            "pageViewFontSize")
                                        .toDouble(),
                                    fontFamily: getValue(
                                        "selectedFontFamily"),
                                  ),
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
                                              jsonData:
                                                  widget.jsonData),
                                        ));
                                        if (index != 187 &&
                                            index != 1) {
                                          spans.add(WidgetSpan(
                                            child: Basmallah(
                                                index: getValue(
                                                    "quranPageolorsIndex")),
                                          ));
                                        }
                                        if (index == 187) {
                                          spans.add(WidgetSpan(
                                            child: Container(
                                              height: 10.h,
                                            ),
                                          ));
                                        }
                                      }

                                      // Verses
                                      spans.add(TextSpan(
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
                                                        selectedSpan =
                                                            "";
                                                      }),
                                        text: i == e["start"]
                                            ? "${quran.getVerseQCF(e["surah"], i).replaceAll(" ", "").substring(0, 1)}\u200A${quran.getVerseQCF(e["surah"], i).replaceAll(" ", "").substring(1)}"
                                            : quran
                                                .getVerseQCF(
                                                    e["surah"], i)
                                                .replaceAll(' ', ''),
                                        style: TextStyle(
                                          color: primaryColors[getValue(
                                              "quranPageolorsIndex")],
                                          height: (index == 1 ||
                                                  index == 2)
                                              ? 2.0
                                              : 1.95,
                                          letterSpacing: 0.w,
                                          wordSpacing: 0,
                                          fontFamily:
                                              "QCF_P${index.toString().padLeft(3, "0")}",
                                          fontSize: index == 1 ||
                                                  index == 2
                                              ? 28.sp
                                              : index == 145 ||
                                                       index == 201
                                                  ? index == 532 ||
                                                           index == 533
                                                       ? 22.5.sp
                                                       : 22.4.sp
                                                  : 22.9.sp,
                                          backgroundColor: widget.shouldHighlightText
                                              ? quran.getVerse(e["surah"], i) ==
                                                       widget.highlightVerse
                                                  ? highlightColors[getValue("quranPageolorsIndex")].withOpacity(.25)
                                                  : selectedSpan == " ${e["surah"]}$i"
                                                      ? highlightColors[getValue("quranPageolorsIndex")].withOpacity(.25)
                                                      : Colors.transparent
                                              : selectedSpan == " ${e["surah"]}$i"
                                                  ? highlightColors[getValue("quranPageolorsIndex")].withOpacity(.25)
                                                  : Colors.transparent,
                                        ),
                                        children: const <TextSpan>[],
                                      ));
                                    }
                                    return spans;
                                  }).toList(),
                                ),
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
          },
        );
      },
    );
  }
}
