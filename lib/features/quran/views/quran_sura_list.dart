import 'package:easy_container/easy_container.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masged_parent_app/features/quran/helpers/constants.dart';
import 'package:masged_parent_app/features/quran/helpers/hive_helper.dart';
import 'package:masged_parent_app/features/quran/views/quranDetailsPage.dart';
import 'package:masged_parent_app/features/quran/widgets/hizb_quarter_circle.dart';
import 'package:masged_parent_app/features/quran/models/surah.dart';

import 'package:quran/quran.dart' as quran;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttericon/font_awesome_icons.dart';
import 'package:group_list_view/group_list_view.dart';
import 'package:flutter/material.dart' as m;
import 'package:string_validator/string_validator.dart';

class SurahListPage extends ConsumerStatefulWidget {
  var jsonData;
  var quarterjsonData;
  SurahListPage(
      {Key? key, required this.jsonData, required this.quarterjsonData})
      : super(key: key);

  @override
  ConsumerState<SurahListPage> createState() => _SurahListPageState();
}

class _SurahListPageState extends ConsumerState<SurahListPage> {
  bool isLoading = true;
  @override
  void dispose() {
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
    // overlays: SystemUiOverlay.values); // TODO: implement dispose
    super.dispose();
  }

  List pageNumbers = [];
  TextEditingController textEditingController = TextEditingController();
  Widget _buildShimmerLoading() {
    return ListView.builder(
      itemCount: 10, // Choose a suitable number of shimmering items
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300.withValues(alpha: .5),
          highlightColor: getValue("darkMode")
              ? darkModeSecondaryColor
              : quranPagesColorLight,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0.w, vertical: 8.h),
            child: ListTile(
              leading: Container(
                width: 45,
                height: 45,
                color: backgroundColor, // Shimmer effect
              ),
              title: Container(
                height: 15,
                color: backgroundColor, // Shimmer effect
              ),
              subtitle: Container(
                height: 12,
                color: backgroundColor, // Shimmer effect
              ),
            ),
          ),
        );
      },
    );
  }

  getCircleWidget(index, hizbNumber) {
    if (index == 0) {
      return Container(
        width: 33.sp,
        height: 33.sp,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: getValue("darkMode")
              ? quranPagesColorDark
              : quranPagesColorLight.withOpacity(.1), // Replace with your logic
        ),
        child: Center(
          child: Text(
            hizbNumber.toString(),
            style: TextStyle(
                fontSize: 14.sp,
                color: getValue("darkMode")
                    ? orangeColor
                    : const Color.fromARGB(228, 0, 0, 0)),
          ),
        ),
      );
    } else if (index == 1) {
      return Container(
          width: 20.sp,
          height: 20.sp,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: getValue("darkMode")
                ? quranPagesColorDark
                : quranPagesColorLight
                    .withOpacity(.1), // Replace with your logic
          ),
          child: QuarterCircle(
              color: getValue("darkMode")
                  ? orangeColor
                  : const Color.fromARGB(228, 0, 0, 0),
              size: 20.sp));
    } else if (index == 2) {
      return Container(
          width: 20.sp,
          height: 20.sp,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: getValue("darkMode")
                ? quranPagesColorDark
                : quranPagesColorLight
                    .withOpacity(.1), // Replace with your logic
          ),
          child: HalfCircle(
              color: getValue("darkMode")
                  ? orangeColor
                  : const Color.fromARGB(228, 0, 0, 0),
              size: 20.sp));
    } else if (index == 3) {
      return Container(
          width: 20.sp,
          height: 20.sp,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: getValue("darkMode")
                ? quranPagesColorDark
                : quranPagesColorLight
                    .withOpacity(.1), // Replace with your logic
          ),
          child: ThreeQuartersCircle(
              color: getValue("darkMode")
                  ? orangeColor
                  : const Color.fromARGB(228, 0, 0, 0),
              size: 20.sp));
    }
  }

  var searchQuery = "";
  var filteredData;
  @override
  void initState() {
    getValue("lastRead") != "non" ?? getJuzNumber();
    // getJuzNumber();
    addFilteredData(); // TODO: implement initState
    super.initState();
  }

  int juzNumberLastRead = 0;
  getJuzNumber() async {
    juzNumberLastRead = quran.getJuzNumber(
        quran.getPageData(getValue("lastRead"))[0]["surah"],
        quran.getPageData(getValue("lastRead"))[0]["start"]);
    // print(juzNumberLastRead);
    setState(() {});
    // await Future.delayed(const Duration(milliseconds: 300));
    // _juzScrollController.scrollTo(
    //     index: juzNumberLastRead-1, duration: const Duration(milliseconds: 500));
  }

  int quarterNumberLastRead = 0;
  getJquarterNumber() async {
    final lastRead = getValue("lastRead");
    if (lastRead != null && lastRead != "non") {
      juzNumberLastRead = quran.getJuzNumber(
          quran.getPageData(lastRead)[0]["surah"],
          quran.getPageData(lastRead)[0]["start"]);
    }
    setState(() {});
    // await Future.delayed(const Duration(milliseconds: 300));
    // _juzScrollController.scrollTo(
    //     index: juzNumberLastRead-1, duration: const Duration(milliseconds: 500));
  }

  final ItemScrollController _juzScrollController = ItemScrollController();

  addFilteredData() async {
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() {
      filteredData = widget.jsonData;
      isLoading = false;
    });
  }

  List<Surah> surahList = [];
  int _currentIndex = 0;

  // Define the tabs
  final List<Tab> tabs = const <Tab>[
    Tab(text: 'سورة'),
    Tab(text: 'جزء'),
    Tab(text: 'ربع'),
  ];
  var ayatFiltered;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Container(
          decoration: BoxDecoration(
              color: getValue("darkMode")
                  ? quranPagesColorDark
                  : quranPagesColorLight),
          child: Scaffold(
              resizeToAvoidBottomInset: false,
              backgroundColor: getValue("darkMode")
                  ? quranPagesColorDark
                  : quranPagesColorLight,
              appBar: PreferredSize(
                preferredSize: Size(MediaQuery.of(context).size.width.w, 80.h),
                child: AppBar(
                  leading: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.0.w, vertical: 8.h),
                    child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios,
                          size: 20.sp,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        }),
                  ),
                  bottom: PreferredSize(
                    preferredSize: Size(
                      MediaQuery.of(context).size.width,
                      MediaQuery.of(context).size.height * 0.04,
                    ),
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height * 0.04,
                      decoration: BoxDecoration(
                        color: Colors
                            .transparent, // Change this to your desired color
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: TabBar(
                        indicatorPadding:
                            EdgeInsets.symmetric(horizontal: 20.w),
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicatorColor: Colors.white,
                        indicatorWeight: 4,
                        tabs: tabs,
                        onTap: (index) {
                          setState(() {
                            _currentIndex = index;
                          });
                          // if(index==1)getJuzNumber();
                        },
                      ),
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(16.r),
                          bottomRight: Radius.circular(16.r))),
                  elevation: 0,
                  centerTitle: true,
                  backgroundColor:
                      getValue("darkMode") ? darkModeSecondaryColor : blueColor,
                  title: Text(
                    "القرآن الكريم",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.sp,
                    ),
                  ),
                ),
              ),
              body: TabBarView(
                children: [
                  SafeArea(
                    child: Container(
                      color: getValue("darkMode")
                          ? quranPagesColorDark
                          : quranPagesColorLight,
                      child: Column(
                        children: [
                          if (getValue("lastRead") != "non")
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: EasyContainer(
                                  color: orangeColor,
                                  height: 60.h,
                                  padding: 0,
                                  margin: 0,
                                  borderRadius: 15.r,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12.0.w),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "اخر ما تم قرائته",
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                        Text(
                                            "${quran.getSurahNameArabic(quran.getPageData(getValue("lastRead"))[0]["surah"])} - ${getValue("lastRead")}",
                                            style: const TextStyle(
                                                color: Colors.white)),
                                        const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 18,
                                          color: Colors.white,
                                        )
                                      ],
                                    ),
                                  ),
                                  onTap: () async {
                                    await Navigator.push(
                                        context,
                                        CupertinoPageRoute(
                                            builder: (builder) =>
                                                QuranDetailsPage(
                                                    shouldHighlightSura:
                                                        false,
                                                    pageNumber:
                                                        getValue("lastRead"),
                                                    jsonData: widget.jsonData,
                                                    shouldHighlightText:
                                                        false,
                                                    highlightVerse: "",
                                                    quarterJsonData: widget
                                                        .quarterjsonData),
                                                ));
                                    setState(() {});
                                  }),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 8.0.w),
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: goldColor.withOpacity(.05),
                                          borderRadius:
                                              BorderRadius.circular(12.r)),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 12.0.w),
                                              child: TextField(
                                                textDirection:
                                                    m.TextDirection.rtl,
                                                controller:
                                                    textEditingController,
                                                onChanged: (value) {
                                                  setState(() {
                                                    searchQuery = value;
                                                  });
                                                  if (value == "") {
                                                    filteredData =
                                                        widget.jsonData;
                                                    pageNumbers = [];
                                                    setState(() {});
                                                  }
                                                  /*https://api.alquran.cloud/v1/search/%D8%A7%D8%A8%D8%B1%D8%A7%D9%87%D9%8A%D9%85/all/ar*/
                                                  if (searchQuery.isNotEmpty &&
                                                      isInt(searchQuery)) {
                                                    pageNumbers.add(
                                                        toInt(searchQuery));
                                                  }
                                                  if (searchQuery.length > 3 ||
                                                      searchQuery
                                                          .toString()
                                                          .contains(" ")) {
                                                    setState(() {
                                                      ayatFiltered = [];
                                                      searchQuery = value;

                                                      ayatFiltered =
                                                          quran.searchWords(
                                                              searchQuery);
                                                      filteredData = widget
                                                          .jsonData
                                                          .where((sura) {
                                                        final suraName =
                                                            sura['englishName']
                                                                .toLowerCase();
                                                        final suraNameTranslated =
                                                            quran.getSurahNameArabic(
                                                                sura["number"]);

                                                        return suraName.contains(
                                                                searchQuery
                                                                    .toLowerCase()) ||
                                                            suraNameTranslated
                                                                .contains(
                                                                    searchQuery
                                                                        .toLowerCase());
                                                      }).toList();
                                                    });
                                                  }
                                                },
                                                style: TextStyle(
                                                    fontFamily: "aldahabi",
                                                    color: getValue("darkMode")
                                                        ? const Color.fromARGB(
                                                            228, 255, 255, 255)
                                                        : const Color.fromARGB(
                                                            190, 0, 0, 0)),
                                                cursorColor:
                                                    getValue("darkMode")
                                                        ? quranPagesColorDark
                                                        : quranPagesColorLight,
                                                decoration: InputDecoration(
                                                  hintText: 'ابحث عن سورة او اية او صفحة',
                                                  hintStyle: TextStyle(
                                                      fontFamily: "aldahabi",
                                                      color:
                                                          getValue("darkMode")
                                                              ? Colors.white70
                                                              : const Color
                                                                  .fromARGB(
                                                                  73, 0, 0, 0)),
                                                  border: InputBorder.none,
                                                ),
                                              ),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              if (searchQuery.isNotEmpty) {
                                                filteredData = widget.jsonData;
                                                textEditingController.clear();
                                                pageNumbers.clear();
                                                setState(() {
                                                  searchQuery = "";
                                                });
                                              }
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: searchQuery.isNotEmpty
                                                  ? Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8.0),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        child: Icon(Icons.close,
                                                            color: getValue(
                                                                    "darkMode")
                                                                ? Colors.white70
                                                                : const Color
                                                                    .fromARGB(
                                                                    73,
                                                                    0,
                                                                    0,
                                                                    0)),
                                                      ),
                                                    )
                                                  : Container(
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        child: Icon(
                                                            FontAwesome.search,
                                                            color: getValue(
                                                                    "darkMode")
                                                                ? Colors.white70
                                                                : const Color
                                                                    .fromARGB(
                                                                    73,
                                                                    0,
                                                                    0,
                                                                    0)),
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: isLoading
                                ? _buildShimmerLoading()
                                : ListView(
                                    shrinkWrap: true,
                                    physics: const ClampingScrollPhysics(),
                                    children: [
                                      if (pageNumbers.isNotEmpty)
                                        Container(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: const Text("صفحة"),
                                          ),
                                        ),
                                      ListView.separated(
                                          reverse: true,
                                          itemBuilder: (ctx, index) {
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.all(5.0),
                                              child: EasyContainer(
                                                color:
                                                    goldColor.withOpacity(.05),
                                                onTap: () {
                                                  Navigator.push(
                                                      context,
                                                      CupertinoPageRoute(
                                                          builder: (builder) =>
                                                              QuranDetailsPage(
                                                                  shouldHighlightSura:
                                                                      true,
                                                                  shouldHighlightText:
                                                                      false,
                                                                  highlightVerse:
                                                                      "",
                                                                  jsonData: widget
                                                                      .jsonData,
                                                                  quarterJsonData:
                                                                      widget
                                                                          .quarterjsonData,
                                                                  pageNumber:
                                                                      pageNumbers[
                                                                          index])));
                                                },
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(pageNumbers[index]
                                                          .toString()),
                                                      Text(quran.getSurahName(
                                                          quran.getPageData(
                                                                  pageNumbers[
                                                                      index])[0]
                                                              ["surah"]))
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          separatorBuilder: (context, index) =>
                                              Padding(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 8.0.w),
                                                child: Divider(
                                                  color: Colors.grey
                                                      .withOpacity(.5),
                                                ),
                                              ),
                                          itemCount: pageNumbers.length),
                                      ListView.separated(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        separatorBuilder: (context, index) =>
                                            Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 8.0.w),
                                          child: Divider(
                                            color: Colors.grey.withOpacity(.5),
                                          ),
                                        ),
                                        itemCount: filteredData.length,
                                        itemBuilder: (context, index) {
                                          int suraNumberInQuran =
                                              filteredData[index]["number"];
                                          int ayahCount = quran
                                              .getVerseCount(suraNumberInQuran);

                                          return Padding(
                                            padding: const EdgeInsets.all(0.0),
                                            child: Container(
                                              child: ListTile(
                                                leading: Container(
                                                  width: 45,
                                                  height: 45,
                                                  decoration:
                                                      const BoxDecoration(
                                                          image:
                                                              DecorationImage(
                                                    image: AssetImage(
                                                      "assets/images/sura_frame.png",
                                                    ),
                                                  )),
                                                  child: Center(
                                                    child: Text(
                                                      suraNumberInQuran
                                                          .toString(),
                                                      style: TextStyle(
                                                          color: orangeColor,
                                                          fontSize: 14.sp),
                                                    ),
                                                  ),
                                                ) //  Material(

                                                ,
                                                minVerticalPadding: 0,
                                                title: RichText(
                                                  text: TextSpan(
                                                    text: "$suraNumberInQuran",
                                                    style: TextStyle(
                                                      color: getValue(
                                                              "darkMode")
                                                          ? Colors.white70
                                                          : Colors.black,
                                                      fontSize: 28.sp,
                                                      fontFamily: "arsura",
                                                    ),
                                                  ),
                                                ),
                                                trailing: Text(
                                                  "$ayahCount",
                                                  style: TextStyle(
                                                      fontFamily: "uthmanic",
                                                      fontSize: 14.sp,
                                                      color: Colors.grey
                                                          .withOpacity(.8)),
                                                ),
                                                onTap: () async {
                                                  await Navigator.push(
                                                      context,
                                                        CupertinoPageRoute(
                                                            builder: (builder) =>
                                                                QuranDetailsPage(
                                                                    shouldHighlightSura:
                                                                        true,
                                                                    shouldHighlightText:
                                                                        false,
                                                                    highlightVerse:
                                                                        "",
                                                                    jsonData: widget
                                                                        .jsonData,
                                                                    quarterJsonData:
                                                                        widget
                                                                            .quarterjsonData,
                                                                    pageNumber:
                                                                        quran.getPageNumber(
                                                                            suraNumberInQuran,
                                                                            1))));
                                                  // Handle tapping on a sura item here
                                                  // You can navigate to the sura details page or perform any other action.
                                                },
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      if (ayatFiltered != null) const Divider(),
                                      if (ayatFiltered != null)
                                        ListView.builder(
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          shrinkWrap: true,
                                          itemCount:
                                              ayatFiltered["occurences"] > 10
                                                  ? 10
                                                  : ayatFiltered["occurences"],
                                          itemBuilder: (context, index) {
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.all(6.0),
                                              child: EasyContainer(
                                                color: getValue("darkMode")
                                                    ? darkModeSecondaryColor
                                                    : Colors.white70,
                                                borderRadius: 14,
                                                onTap: () async {
                                                  await Navigator.push(
                                                      context,
                                                      CupertinoPageRoute(
                                                          builder: (builder) =>
                                                              QuranDetailsPage(
                                                                  shouldHighlightSura:
                                                                      false,
                                                                  pageNumber: quran
                                                                      .getPageNumber(
                                                                    ayatFiltered["result"]
                                                                        [index]["surah"],
                                                                    ayatFiltered["result"]
                                                                        [index]["verse"],
                                                                  ),
                                                                  jsonData:
                                                                      widget.jsonData,
                                                                  shouldHighlightText:
                                                                      true,
                                                                  highlightVerse:
                                                                      quran.getVerse(
                                                                    ayatFiltered["result"]
                                                                        [index]["surah"],
                                                                    ayatFiltered["result"]
                                                                        [index]["verse"],
                                                                  ),
                                                                  quarterJsonData: widget
                                                                      .quarterjsonData)));
                                                },
                                                child: Text(
                                                  "سورة ${quran.getSurahNameArabic(ayatFiltered["result"][index]["surah"])} - ${quran.getVerse(ayatFiltered["result"][index]["surah"], ayatFiltered["result"][index]["verse"], verseEndSymbol: true)}",
                                                  textDirection:
                                                      m.TextDirection.rtl,
                                                  style: TextStyle(
                                                      color:
                                                          getValue("darkMode")
                                                              ? Colors.white
                                                              : Colors.black,
                                                      fontFamily: "uthmanic",
                                                      fontSize: 17.sp),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // const Text("data"),
                  ScrollablePositionedList.builder(
                    itemCount: 30,
                    itemScrollController: _juzScrollController,
                    itemBuilder: (BuildContext context, index) {
                      return Card(
                        color: getValue("darkMode")
                            ? darkModeSecondaryColor.withOpacity(.8)
                            : quranPagesColorLight,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ListTile(
                              title: Text(
                                quran.getSurahNameArabic(quran
                                    .getSurahAndVersesFromJuz(index + 1)
                                    .keys
                                    .first),
                                style: TextStyle(
                                    color: getValue("darkMode")
                                        ? const Color.fromARGB(
                                            234, 255, 255, 255)
                                        : const Color.fromARGB(228, 0, 0, 0)),
                              ),
                              subtitle: Text(
                                quran.getVerse(
                                    quran
                                        .getSurahAndVersesFromJuz(index + 1)
                                        .keys
                                        .first,
                                    quran
                                        .getSurahAndVersesFromJuz(index + 1)
                                        .values
                                        .first[0]),
                                style: TextStyle(
                                    fontFamily: "UthmanicHafs13",
                                    fontSize: 18.sp,
                                    color: getValue("darkMode")
                                        ? const Color.fromARGB(
                                            234, 255, 255, 255)
                                        : const Color.fromARGB(228, 0, 0, 0)
                                    // fontWeight: FontWeight.w600
                                    ),
                              ),
                              onTap: () async {
                                await Navigator.push(
                                    context,
                                      CupertinoPageRoute(
                                          builder: (builder) => QuranDetailsPage(
                                              shouldHighlightSura: false,
                                              quarterJsonData:
                                                  widget.quarterjsonData,
                                              shouldHighlightText: true,
                                              highlightVerse: quran.getVerse(
                                                  quran
                                                      .getSurahAndVersesFromJuz(
                                                          index + 1)
                                                      .keys
                                                      .first,
                                                  quran
                                                      .getSurahAndVersesFromJuz(
                                                          index + 1)
                                                      .values
                                                      .first[0]),
                                              pageNumber: quran.getPageNumber(
                                                  quran
                                                      .getSurahAndVersesFromJuz(
                                                          index + 1)
                                                      .keys
                                                      .first,
                                                  quran
                                                      .getSurahAndVersesFromJuz(
                                                          index + 1)
                                                      .values
                                                      .first[0]),
                                              jsonData: widget.jsonData)));
                                getJuzNumber();
                                setState(() {});
                              },
                              leading: Container(
                                width: 33.sp,
                                height: 33.sp,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: juzNumberLastRead == index + 1
                                      ? getValue("darkMode")
                                          ? quranPagesColorDark
                                          : quranPagesColorLight
                                      : getValue("darkMode")
                                          ? quranPagesColorDark
                                          : quranPagesColorLight.withOpacity(
                                              .1), // Replace with your logic
                                ),
                                child: Center(
                                  child: Text(
                                    (index + 1).toString(),
                                    style: TextStyle(
                                        fontSize: 14.sp,
                                        color: getValue("darkMode")
                                            ? orangeColor
                                            : const Color.fromARGB(
                                                228, 0, 0, 0)),
                                  ),
                                ),
                              )),
                        ),
                      );
                    },
                  ),

                  GroupListView(
                    sectionsCount: 60,
                    countOfItemInSection: (int section) {
                      return 4;
                    },
                    itemBuilder: (BuildContext context, IndexPath index) {
                      return Card(
                        color: getValue("darkMode")
                            ? darkModeSecondaryColor.withOpacity(.8)
                            : quranPagesColorLight,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ListTile(
                            title: Text(
                              quran.getSurahNameArabic(widget.quarterjsonData[
                                      indexes[index.section][index.index] - 1]
                                  ["surah"]),
                              style: TextStyle(
                                  color: getValue("darkMode")
                                      ? const Color.fromARGB(234, 255, 255, 255)
                                      : const Color.fromARGB(228, 0, 0, 0)),
                            ),
                            subtitle: Text(
                              quran.getVerse(
                                  widget.quarterjsonData[indexes[index.section]
                                          [index.index] -
                                      1]["surah"],
                                  widget.quarterjsonData[indexes[index.section]
                                          [index.index] -
                                      1]["ayah"]),
                              style: TextStyle(
                                  fontFamily: "UthmanicHafs13",
                                  fontSize: 18.sp,
                                  color: getValue("darkMode")
                                      ? const Color.fromARGB(234, 255, 255, 255)
                                      : const Color.fromARGB(228, 0, 0, 0)
                                  // fontWeight: FontWeight.w600
                                  ),
                            ),
                            onTap: () async {
                              await Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                      builder: (builder) => QuranDetailsPage(
                                          shouldHighlightSura: false,
                                          quarterJsonData:
                                              widget.quarterjsonData,
                                          shouldHighlightText: true,
                                          highlightVerse: quran.getVerse(
                                              widget.quarterjsonData[indexes[index.section][index.index] - 1]
                                                  ["surah"],
                                              widget.quarterjsonData[indexes[index.section][index.index] - 1]
                                                  ["ayah"]),
                                          pageNumber: quran.getPageNumber(
                                              widget.quarterjsonData[indexes[index.section][index.index] - 1]
                                                  ["surah"],
                                              widget.quarterjsonData[
                                                  indexes[index.section]
                                                          [index.index] -
                                                      1]["ayah"]),
                                          jsonData: widget.jsonData)));

                              setState(() {});
                            },
                            leading:
                                getCircleWidget(index.index, index.section + 1),
                          ),
                        ),
                      );
                    },
                    groupHeaderBuilder: (BuildContext context, int section) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 8),
                        child: Text(
                          "حزب ${section + 1}",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: getValue("darkMode")
                                  ? const Color.fromARGB(234, 255, 255, 255)
                                  : const Color.fromARGB(228, 0, 0, 0)),
                        ),
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    sectionSeparatorBuilder: (context, section) =>
                        const SizedBox(height: 10),
                  ),
                ],
              )),
        ),
      ),
    );
  }
}
