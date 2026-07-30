import 'package:masged_parent_app/features/quran/helpers/translation/translation_info.dart';

enum Translation {
  baghawy,
  e3rab,
  katheer,
  qortoby,
  sa3dy,
  tabary,
  waseet,
  ar_ma3any,
  ar_muyassar,
  bn_bengali,
  bs_korkut,
  de_bubenheim,
  en_sahih,
  es_navio,
  fr_hamidullah,
  ha_gumi,
  id_indonesian,
  indonesian,
  it_piccardo,
  ku_asan,
  ml_abdulhameed,
  ms_basmeih,
  nl_siregar,
  pr_tagi,
  pt_elhayek,
  ru_kuliev,
  russian,
  so_abduh,
  sq_nahi,
  sv_bernstrom,
  sw_barwani,
  ta_tamil,
  th_thai,
  tr_diyanet,
  ur_jalandhry,
  uz_sodik,
  zh_jian,
  tafheem,
  tanweer,
}

List<TranslationData> translationDataList = [
  TranslationData(
    typeText: 'ar_muyassar',
    typeTextInRelatedLanguage: 'التفسير الميسر',
    typeInNativeLanguage: 'العربية',
    typeAsEnumValue: Translation.ar_muyassar,
    url: "  d"
  ),
  TranslationData(
    typeText: 'baghawy',
    typeTextInRelatedLanguage: 'تفسير البغوي',
    typeInNativeLanguage: 'العربية',
    typeAsEnumValue: Translation.baghawy,    url: "https://raw.githubusercontent.com/noureddin/Quran-App-Data/main/Tafaseer/baghawy.json"
  ),
  TranslationData(
    typeText: 'e3rab',
    typeTextInRelatedLanguage: 'إعراب كلمات القرآن الكريم',
    typeInNativeLanguage: 'العربية',
    typeAsEnumValue: Translation.e3rab, url: "https://raw.githubusercontent.com/noureddin/Quran-App-Data/main/Tafaseer/e3rab.json"
  ),
  TranslationData(
    typeText: 'katheer',
    typeTextInRelatedLanguage: 'تفسير ابن كثير',
    typeInNativeLanguage: 'العربية',
    typeAsEnumValue: Translation.katheer, url: "https://raw.githubusercontent.com/noureddin/Quran-App-Data/main/Tafaseer/katheer.json"
  ),
  TranslationData(
    typeText: 'qortoby',
    typeTextInRelatedLanguage: 'تفسير القرطبي',
    typeInNativeLanguage: 'العربية',
    typeAsEnumValue: Translation.qortoby, url: "https://raw.githubusercontent.com/noureddin/Quran-App-Data/main/Tafaseer/qortoby.json"
  ),
  TranslationData(
    typeText: 'sa3dy',
    typeTextInRelatedLanguage: 'تفسير السعدي',
    typeInNativeLanguage: 'العربية',
    typeAsEnumValue: Translation.sa3dy, url: "https://raw.githubusercontent.com/noureddin/Quran-App-Data/main/Tafaseer/sa3dy.json"
  ),
  TranslationData(
    typeText: 'tabary',
    typeTextInRelatedLanguage: 'تفسير الطبري',
    typeInNativeLanguage: 'العربية',
    typeAsEnumValue: Translation.tabary, url: "https://raw.githubusercontent.com/noureddin/Quran-App-Data/main/Tafaseer/tabary.json"
  ),
  TranslationData(
    typeText: 'waseet',
    typeTextInRelatedLanguage: 'التفسير الوسيط',
    typeInNativeLanguage: 'العربية',
    typeAsEnumValue: Translation.waseet, url: "https://raw.githubusercontent.com/noureddin/Quran-App-Data/main/Tafaseer/waseet.json"
  ),
  TranslationData(
    typeText: 'ar_ma3any',
    typeTextInRelatedLanguage: 'معاني الكلمات',
    typeInNativeLanguage: 'العربية',
    typeAsEnumValue: Translation.ar_ma3any, url: "https://raw.githubusercontent.com/noureddin/Quran-App-Data/main/Tafaseer/ar_ma3any.json"
  ),
  TranslationData(
    typeText: 'tanweer',
    typeTextInRelatedLanguage: 'تفسير التحرير والتنوير',
    typeInNativeLanguage: 'العربية',
    typeAsEnumValue: Translation.tanweer,
    url: "https://raw.githubusercontent.com/noureddin/Quran-App-Data/main/Tafaseer/tanweer.json"
  ),
];
