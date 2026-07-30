import 'dart:io';

/// Removes QCF_P### font registrations from pubspec.yaml (604 entries).
/// QCF page fonts are loaded on demand via [QcfFontLoader] instead.
void main() {
  final file = File('pubspec.yaml');
  if (!file.existsSync()) {
    stderr.writeln('Run from ParentApp/: pubspec.yaml not found');
    exit(1);
  }

  final lines = file.readAsLinesSync();
  final out = <String>[];
  var skipping = false;

  for (final line in lines) {
    if (line.startsWith('    - family: QCF_P')) {
      skipping = true;
      continue;
    }
    if (skipping) {
      if (line.startsWith('        - asset: assets/fonts/v2woff/')) {
        continue;
      }
      if (line.trim().isEmpty) {
        skipping = false;
        continue;
      }
      if (!line.startsWith('    ')) {
        skipping = false;
        out.add(line);
        continue;
      }
      if (line.startsWith('    - family:') && !line.contains('QCF_P')) {
        skipping = false;
        out.add(line);
        continue;
      }
      continue;
    }
    out.add(line);
  }

  file.writeAsStringSync('${out.join('\n')}\n');
  stdout.writeln('Removed QCF_P font families from pubspec.yaml');
}
