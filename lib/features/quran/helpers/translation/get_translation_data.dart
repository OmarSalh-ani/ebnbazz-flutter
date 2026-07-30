import 'dart:convert';
import 'dart:io';
import 'package:masged_parent_app/features/quran/helpers/translation/translation_info.dart';
import 'package:masged_parent_app/features/quran/helpers/translation/translationdata.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quran/quran.dart' as q;
String getVerseTranslationForVerseByVerse(var data,
    int surahNumber, int verseNumber, TranslationData translation,
    {bool verseEndSymbol = false})  {
  List<dynamic> translationDataList = [];
    
    translationDataList=data;
  String verse = "";
  for (var item in translationDataList) {
    if (item['sura'].toString() == surahNumber.toString() &&
        item['aya'].toString() == verseNumber.toString()) {
      verse = item['text'];
      break;
    }
  }

  if (verse == "") {
    return "";
  }
print(verse);
  return verse.replaceAll("<br>", "\n") +
      (verseEndSymbol
          ? q.getVerseEndSymbol(verseNumber, arabicNumeral: false)
          : "");
}

Future<String> getVerseTranslation(
    int surahNumber, int verseNumber, TranslationData translation,
    {bool verseEndSymbol = false}) async {
  List<dynamic> translationDataList = [];
  Directory appDir=await getTemporaryDirectory();
    File file = File("${appDir.path}/${translation.typeText}.json");

    String jsonData = await file.readAsString();
    translationDataList = json.decode(jsonData);
  String verse = "";
  for (var item in translationDataList) {
    if (item['sura'].toString() == surahNumber.toString() &&
        item['aya'].toString() == verseNumber.toString()) {
      verse = item['text'];
      break;
    }
  }

  if (verse == "") {
    return "";
  }
  return verse +
      (verseEndSymbol
          ? q.getVerseEndSymbol(verseNumber, arabicNumeral: false)
          : "");
}
