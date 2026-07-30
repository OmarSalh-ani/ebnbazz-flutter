import 'dart:convert';
import 'dart:io';

/// Keeps only icon/Quran fonts the app actually uses on web.
///
/// Run after `flutter build web`:
///   dart run tool/patch_web_font_manifest.dart
void main() {
  final manifestFile = File('build/web/assets/FontManifest.json');
  if (!manifestFile.existsSync()) {
    stderr.writeln('FontManifest.json not found. Run flutter build web first.');
    exit(1);
  }

  const keepFamilies = {
    'MaterialIcons',
    'cairo',
    'AmiriQuran',
    'UthmanicHafs13',
    'KFGQPC Uthmanic Script HAFS Regular',
    'packages/fluttericon/FontAwesome',
    'packages/fluttericon/FontAwesome5',
    'packages/fluttericon/MfgLabs',
  };

  const keepPrefixes = ['QCF_P'];

  final raw = jsonDecode(manifestFile.readAsStringSync()) as List<dynamic>;
  final filtered = raw.where((entry) {
    final family = (entry as Map<String, dynamic>)['family'] as String;
    if (keepFamilies.contains(family)) return true;
    return keepPrefixes.any(family.startsWith);
  }).toList();

  manifestFile.writeAsStringSync(jsonEncode(filtered));
  stdout.writeln(
    'FontManifest trimmed: ${raw.length} -> ${filtered.length} families',
  );
}
