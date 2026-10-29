// Fails if `Color(0x..)` hex literals or `Colors.*` references appear in
// lib/ outside lib/core/theme/ (except `Colors.transparent`, which marks
// intentional see-through regions, not surfaces).
//
// Run: dart tool/check_hardcoded_colors.dart
// (also wrapped by tool/check_hardcoded_colors.sh for CI).
import 'dart:io';

final _colorHex = RegExp(r'Color\s*\(\s*0x');
// `AppColors.` contains the substring `Colors.` — exclude it.
final _materialColors = RegExp(r'(?<!App)Colors\.([A-Za-z0-9_]+)');

void main() {
  final lib = Directory('lib');
  if (!lib.existsSync()) {
    stderr.writeln('Run from the repo root (lib/ not found).');
    exit(2);
  }
  final violations = <String>[];
  for (final file
      in lib
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path))) {
    final rel = file.path.replaceAll(r'\', '/');
    if (rel.startsWith('lib/core/theme/')) continue;
    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (_colorHex.hasMatch(line)) {
        violations.add('${file.path}:${i + 1}: hex Color literal');
      }
      for (final m in _materialColors.allMatches(line)) {
        if (m.group(1) == 'transparent') continue;
        violations.add('${file.path}:${i + 1}: Colors.${m.group(1)}');
      }
    }
  }
  if (violations.isEmpty) {
    stdout.writeln('OK: no hardcoded colors outside lib/core/theme/.');
    return;
  }
  stderr.writeln('Hardcoded colors outside lib/core/theme/:');
  for (final v in violations) {
    stderr.writeln('  $v');
  }
  stderr.writeln(
    'Fix: use Theme.of(context).colorScheme / context.tokens instead.',
  );
  exit(1);
}
