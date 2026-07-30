import 'package:easy_container/easy_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:masged_parent_app/features/quran/helpers/constants.dart';
import 'package:masged_parent_app/features/quran/helpers/hive_helper.dart';
import 'package:masged_parent_app/features/quran/helpers/quran_page_utils.dart';
import 'package:quran/quran.dart';

class QuranPageHeader extends StatelessWidget {
  final int index;
  final dynamic jsonData;
  final dynamic quarterJsonData;
  final VoidCallback onBack;
  final VoidCallback onSettings;

  const QuranPageHeader({
    Key? key,
    required this.index,
    required this.jsonData,
    required this.quarterJsonData,
    required this.onBack,
    required this.onSettings,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final pageData = getPageData(index);
    final surahNumber = pageData[0]["surah"];
    final surahName = jsonData[surahNumber - 1]["name"];

    return SizedBox(
      width: screenSize.width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                IconButton(
                    onPressed: onBack,
                    icon: Icon(
                      Icons.arrow_back_ios,
                      size: 24.sp,
                      color: secondaryColors[getValue("quranPageolorsIndex")],
                    )),
                Flexible(
                  child: Text(surahName,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: secondaryColors[getValue("quranPageolorsIndex")],
                          fontFamily: "Taha",
                          fontSize: 14.sp)),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Center(
              child: _buildPageInfoChunk(index, pageData),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                    onPressed: onSettings,
                    icon: Icon(
                      Icons.settings,
                      size: 24.sp,
                      color: secondaryColors[getValue("quranPageolorsIndex")],
                    ))
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPageInfoChunk(int index, dynamic pageData) {
    final result = QuranPageUtils.checkIfPageIncludesQuarterAndQuarterIndex(
        quarterJsonData, pageData, indexes);

    if (result.includesQuarter) {
      return EasyContainer(
        borderRadius: 12.r,
        color: secondaryColors[getValue("quranPageolorsIndex")].withOpacity(.5),
        borderColor: primaryColors[getValue("quranPageolorsIndex")],
        showBorder: true,
        height: 20.h,
        width: 160.w,
        padding: 0,
        margin: 0,
        child: Text(
          result.includesQuarter == true
              ? "صفحة ${(index).toString()} | ${(result.quarterIndex + 1) == 1 ? "" : "${(result.quarterIndex).toString()}/${4.toString()}"} حزب ${(result.hizbIndex + 1).toString()} | جزء ${getJuzNumber(pageData[0]["surah"], pageData[0]["start"])} "
              : "صفحة $index | جزء ${getJuzNumber(pageData[0]["surah"], pageData[0]["start"])}",
          style: TextStyle(
            fontFamily: 'aldahabi',
            fontSize: 10.sp,
            color: backgroundColors[getValue("quranPageolorsIndex")],
          ),
        ),
      );
    } else {
      return EasyContainer(
        borderRadius: 12.r,
        color: secondaryColors[getValue("quranPageolorsIndex")].withOpacity(.5),
        borderColor: backgroundColors[getValue("quranPageolorsIndex")],
        showBorder: true,
        height: 20.h,
        width: 120.w,
        padding: 0,
        margin: 0,
        child: Center(
          child: Text(
            "صفحة $index | جزء ${getJuzNumber(pageData[0]["surah"], pageData[0]["start"])}",
            style: TextStyle(
              fontFamily: 'aldahabi',
              fontSize: 12.sp,
              color: backgroundColors[getValue("quranPageolorsIndex")],
            ),
          ),
        ),
      );
    }
  }
}
