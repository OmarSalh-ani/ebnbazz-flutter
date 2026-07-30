/// Kuwait server timezone (+03:00) helpers for chat timestamps from the API.

const Duration _kuwaitOffset = Duration(hours: 3);

/// Wall-clock [DateTime] in Kuwait for displaying chat message times from the server.
DateTime parseChatServerTime(dynamic raw) {
  if (raw == null) return _epoch;

  final text = raw.toString().trim();
  if (text.isEmpty) return _epoch;

  final parsed = DateTime.tryParse(text);
  if (parsed == null) return _epoch;

  final hasExplicitOffset =
      text.endsWith('Z') || RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(text);

  if (!hasExplicitOffset) {
    // Legacy / unspecified values are already Kuwait local wall clock.
    return DateTime(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
    );
  }

  final utc = parsed.toUtc();
  final kuwait = utc.add(_kuwaitOffset);
  return DateTime(
    kuwait.year,
    kuwait.month,
    kuwait.day,
    kuwait.hour,
    kuwait.minute,
    kuwait.second,
    kuwait.millisecond,
  );
}

/// Today's calendar date in Kuwait (matches backend [KuwaitTime.Today]).
DateTime kuwaitServerToday() {
  final utc = DateTime.now().toUtc();
  final kuwait = utc.add(_kuwaitOffset);
  return DateTime(kuwait.year, kuwait.month, kuwait.day);
}

DateTime? parseChatServerTimeOrNull(dynamic raw) {
  if (raw == null) return null;
  final text = raw.toString().trim();
  if (text.isEmpty) return null;
  final parsed = parseChatServerTime(raw);
  return parsed == _epoch ? null : parsed;
}

final DateTime _epoch = DateTime(1970, 1, 1);
