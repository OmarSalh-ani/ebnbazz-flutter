/// Normalizes Arabic text for in-app name search.
///
/// Strips bidirectional marks (often injected by RTL [TextField]s), diacritics,
/// and extra whitespace so queries like "ف" match "فالح".
String normalizeForArabicSearch(String text) {
  var normalized = text.replaceAll(RegExp(r'[\u200E\u200F\u202A-\u202E]'), '');
  normalized = normalized.replaceAll(RegExp(r'[\u064B-\u0652]'), '');
  normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
  return normalized;
}

bool arabicNameMatches(String name, String query) {
  final normalizedQuery = normalizeForArabicSearch(query);
  if (normalizedQuery.isEmpty) return true;
  return normalizeForArabicSearch(name).contains(normalizedQuery);
}

bool arabicNameStartsWith(String name, String query) {
  final normalizedQuery = normalizeForArabicSearch(query);
  if (normalizedQuery.isEmpty) return true;
  return normalizeForArabicSearch(name).startsWith(normalizedQuery);
}
