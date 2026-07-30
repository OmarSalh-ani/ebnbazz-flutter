import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masged_parent_app/features/quran/helpers/translation/translationdata.dart';
import 'package:masged_parent_app/features/quran/helpers/quran_page_utils.dart';
import 'package:masged_parent_app/features/quran/widgets/details_page/quran_page_view.dart';
import 'package:masged_parent_app/features/quran/widgets/details_page/quran_vertical_view.dart';
import 'package:masged_parent_app/features/quran/widgets/details_page/quran_verse_by_verse_view.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:masged_parent_app/features/quran/helpers/hive_helper.dart';
import 'package:quran/quran.dart' as quran;

class QuranReadingPage extends StatefulWidget {
  const QuranReadingPage({super.key});

  @override
  State<QuranReadingPage> createState() => _QuranReadingPageState();
}

class _QuranReadingPageState extends State<QuranReadingPage> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class QuranDetailsPage extends ConsumerStatefulWidget {
  int pageNumber;
  var jsonData;
  var quarterJsonData;
  var shouldHighlightText;
  var highlightVerse;
  var shouldHighlightSura;
  // var highlighSurah;
  QuranDetailsPage(
      {super.key,
      required this.pageNumber,
      required this.jsonData,
      required this.shouldHighlightText,
      required this.highlightVerse,
      required this.quarterJsonData,
      required this.shouldHighlightSura});

  @override
  ConsumerState<QuranDetailsPage> createState() => QuranDetailsPageState();
}

class QuranDetailsPageState extends ConsumerState<QuranDetailsPage> {
  final ScrollController _scrollController = ScrollController();
  // var controller;
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  // final bool _isScrolling = false;

  var dataOfCurrentTranslation;
  getTranslationData() async {
    if (kIsWeb) return;
    try {
      final index = getValue("indexOfTranslationInVerseByVerse");
      if (index != null && index > 1) {
        // This part needs local file access which is not supported on Web as is
        // On mobile, it would use appDir (which we removed or need to handle)
        // For now, we skip to avoid crashes.
      }
    } catch (e) {
      debugPrint("Error loading translation: $e");
    }
    setState(() {});
  }

  int index = 0;
  setIndex() {
    setState(() {
      index = widget.pageNumber;
    });
  }

  double valueOfSlider = 0;

  late Timer timer;
  initialize() async {
    getTranslationData();
    if (mounted) {
      setState(() {});
    }
  }

  checkIfSelectHighlight() async {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (selectedSpan != "") {
        setState(() {
          selectedSpan = "";
        });
      }
    });
  }

  @override
  void initState() {
    initialize();
    getTranslationData();
    checkIfSelectHighlight();
    setIndex();

    changeHighlightSurah();

    highlightVerseFunction();
    _scrollController.addListener(_scrollListener);

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _pageController = PageController(initialPage: index);
    _pageController.addListener(_pagecontroller_scrollListner);
    updateValue("lastRead", widget.pageNumber);
    super.initState();
  }

  void _scrollListener() {
    if (_scrollController.position.isScrollingNotifier.value &&
        selectedSpan != "") {
      setState(() {
        selectedSpan = "";
      });
    } else {}
  }

  void _pagecontroller_scrollListner() {
    if (_pageController.position.isScrollingNotifier.value &&
        selectedSpan != "") {
      setState(() {
        selectedSpan = "";
      });
    } else {}
  }

  var highlightVerse;
  var shouldHighlightText;
  changeHighlightSurah() async {
    await Future.delayed(const Duration(seconds: 2));
    widget.shouldHighlightSura = false;
  }

  highlightVerseFunction() {
    setState(() {
      shouldHighlightText = widget.shouldHighlightText;
    });
    if (widget.shouldHighlightText) {
      setState(() {
        highlightVerse = widget.highlightVerse;
      });

      Timer.periodic(const Duration(milliseconds: 400), (timer) {
        if (mounted) {
          setState(() {
            shouldHighlightText = false;
          });
        }
        Timer(const Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() {
              shouldHighlightText = true;
            });
          }
          if (timer.tick == 4) {
            if (mounted) {
              setState(() {
                highlightVerse = "";

                shouldHighlightText = false;
              });
            }
            timer.cancel();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    timer.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    getTotalCharacters(quran.getVersesTextByPage(widget.pageNumber));
    super.dispose();
  }

  int total = 0;
  int total1 = 0;
  int total3 = 0;
  int getTotalCharacters(List<String> stringList) {
    return QuranPageUtils.getTotalCharacters(stringList);
  }

  checkIfAyahIsAStartOfSura() {}
  String? swipeDirection;
  late PageController _pageController;

  var english = RegExp(r'[a-zA-Z]');

  String selectedSpan = "";

  double currentHeight = 2.0;
  // double currentWordSpacing = 0.0;
  double currentLetterSpacing = 0.0;

  List<GlobalKey> richTextKeys = List.generate(
    604, // Replace with the number of pages in your PageView
    (_) => GlobalKey(),
  );
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      endDrawer: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width * .5,
      ),
      backgroundColor: Colors.transparent,
      body: Builder(builder: (context) {
        if (getValue("alignmentType") == "pageview") {
            return QuranPageView(
                pageController: _pageController,
                onPageChanged: (index) {
                    setState(() { selectedSpan = ""; });
                    this.index = index;
                    updateValue("lastRead", index);
                },
                onBack: () => Navigator.pop(context),
                onSettings: () { scaffoldKey.currentState?.openEndDrawer(); },
                jsonData: widget.jsonData,
                quarterJsonData: widget.quarterJsonData,
                shouldHighlightText: widget.shouldHighlightText,
                highlightVerse: widget.highlightVerse,
                index: index,
            );
        } else if (getValue("alignmentType") == "verticalview") {
            return QuranVerticalView(
                itemScrollController: itemScrollController,
                itemPositionsListener: itemPositionsListener,
                onPageChanged: (i) {
                     this.index = i;
                     updateValue("lastRead", i);
                },
                jsonData: widget.jsonData,
                quarterJsonData: widget.quarterJsonData,
                shouldHighlightText: widget.shouldHighlightText,
                highlightVerse: widget.highlightVerse,
            );
        } else {
             return QuranVerseByVerseView(
                itemScrollController: itemScrollController,
                itemPositionsListener: itemPositionsListener,
                onPageChanged: (i) {
                     this.index = i;
                     updateValue("lastRead", i);
                },
                jsonData: widget.jsonData,
                shouldHighlightText: widget.shouldHighlightText,
                highlightVerse: widget.highlightVerse,
                translationDataList: translationDataList,
                dataOfCurrentTranslation: dataOfCurrentTranslation,
                onBack: () => Navigator.pop(context),
             );
        }
      }),
    );
  }

  bool showSuraHeader = true;
  bool addAppSlogan = true;
  

  bool isDownloading = false;
  

  
}

