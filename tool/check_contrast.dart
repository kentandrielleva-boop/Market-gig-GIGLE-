// Prints the WCAG contrast ratio for every text/background pair used by the
// Gigl light + dark themes and exits non-zero when a pair misses its target
// (body text >= 4.5:1, large text / UI >= 3:1).
//
// Run: dart tool/check_contrast.dart
import 'dart:io';
import 'dart:math' as math;

double _lin(double c) {
  c /= 255;
  return c <= 0.03928
      ? c / 12.92
      : math.pow((c + 0.055) / 1.055, 2.4) as double;
}

double _lum(int hex) {
  final r = _lin(((hex >> 16) & 0xFF).toDouble());
  final g = _lin(((hex >> 8) & 0xFF).toDouble());
  final b = _lin((hex & 0xFF).toDouble());
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double ratio(int fg, int bg) {
  final a = _lum(fg);
  final b = _lum(bg);
  final hi = math.max(a, b);
  final lo = math.min(a, b);
  return (hi + 0.05) / (lo + 0.05);
}

class _Pair {
  const _Pair(this.name, this.fg, this.bg, this.min);
  final String name;
  final int fg;
  final int bg;
  final double min;
}

int blend(int fg, int bg, double t) {
  int ch(int c, int shift) => (c >> shift) & 0xFF;
  int mix(int a, int b) => (a + (b - a) * t).round().clamp(0, 255);
  return 0xFF000000 |
      (mix(ch(fg, 16), ch(bg, 16)) << 16) |
      (mix(ch(fg, 8), ch(bg, 8)) << 8) |
      mix(ch(fg, 0), ch(bg, 0));
}

void main() {
  // Category gradient starts = base lightened 8% toward white (mirrors
  // GiglCategoryColors.fromBase). Inside-node labels sit on this gradient,
  // so both ends are checked.
  const white = 0xFFFFFFFF;
  final gradLight = {
    'discover': blend(0xFF5B2EC7, white, 0.08),
    'gigs': blend(0xFF0C6E54, white, 0.08),
    'market': blend(0xFFB84A2E, white, 0.08),
    'chats': blend(0xFF1D5FB0, white, 0.08),
    'saved': blend(0xFF8F5C0C, white, 0.08),
    'profile': blend(0xFF475467, white, 0.08),
  };
  final gradDark = {
    'discover': blend(0xFF9B7BFF, white, 0.08),
    'gigs': blend(0xFF3FC6A0, white, 0.08),
    'market': blend(0xFFF08A6A, white, 0.08),
    'chats': blend(0xFF5FA2F0, white, 0.08),
    'saved': blend(0xFFE3A94A, white, 0.08),
    'profile': blend(0xFF9AA6B8, white, 0.08),
  };
  // Dock subtitle = onInk @ 72% opacity over the dock fill. NOTE: blend()
  // mixes fg->bg by t, so 72%-opaque white over ink is t=0.28, not 0.72.
  final dockSubtitleLight = blend(white, 0xFF222222, 0.28);
  final dockSubtitleDark = blend(0xFFF3F0FB, 0xFF221A38, 0.28);
  // Tonal tiles: ink text on base @ 14% over the surface behind the tile.
  int tileLight(int base) => blend(base, white, 0.86);
  int tileDark(int base) => blend(base, 0xFF19132B, 0.86);
  // Worst case: tile/patch zones over decoration. Patches draw 20-40%
  // (30% checked); mesh draws at MotionTokens.meshAlphaLight 50% (light) /
  // meshAlphaDark 30% (dark), butter x0.6 -> 30%/18%; cross-fade drifts
  // colors between the checked neighbor endpoints; glass = white @ 65%
  // over mesh. All four mesh hues checked in both brightnesses.
  int overCream(int c, double t) => blend(c, 0xFFFDFBF7, t);
  int overDarkBg(int c, double t) => blend(c, 0xFF0F0B1A, t);
  int glassOver(int mesh) => blend(white, mesh, 0.35);
  final pairs = [
    // ---- Light theme UI text (cream background)
    const _Pair('light ink/bg', 0xFF222222, 0xFFFDFBF7, 4.5),
    const _Pair('light inkMuted/bg', 0xFF5C5A66, 0xFFFDFBF7, 4.5),
    const _Pair('light inkMuted/surface', 0xFF5C5A66, 0xFFFFFFFF, 4.5),
    const _Pair(
      'light primary/surface (wordmark, links)',
      0xFF5B2EC7,
      0xFFFFFFFF,
      4.5,
    ),
    const _Pair(
      'light brand Post pill (fixed accent)',
      0xFFFFFFFF,
      0xFF5B2EC7,
      4.5,
    ),
    const _Pair(
      'light onPrimary/primary (filled buttons)',
      0xFFFFFFFF,
      0xFF5B2EC7,
      4.5,
    ),
    const _Pair('light error/surface', 0xFFC62F3E, 0xFFFFFFFF, 4.5),
    const _Pair(
      'light primary/primarySoft (secondary buttons)',
      0xFF5B2EC7,
      0xFFEFE9FB,
      4.5,
    ),
    // ---- Ink pills (charcoal pill, white label; dock + subtitle)
    const _Pair(
      'light onPill/pill (ink CTA, selected chips)',
      white,
      0xFF222222,
      4.5,
    ),
    const _Pair('light onInk/ink (dock title)', white, 0xFF222222, 4.5),
    _Pair('light dock subtitle/ink', dockSubtitleLight, 0xFF222222, 4.5),
    // ---- Ink text on tonal tiles (base @ 14% over white)
    _Pair('light tile discover', 0xFF222222, tileLight(0xFF5B2EC7), 4.5),
    _Pair('light tile gigs', 0xFF222222, tileLight(0xFF0C6E54), 4.5),
    _Pair('light tile market', 0xFF222222, tileLight(0xFFB84A2E), 4.5),
    _Pair('light tile chats', 0xFF222222, tileLight(0xFF1D5FB0), 4.5),
    _Pair('light tile saved', 0xFF222222, tileLight(0xFF8F5C0C), 4.5),
    _Pair('light tile profile', 0xFF222222, tileLight(0xFF475467), 4.5),
    // ---- Worst case: ink text over patches / mesh / glass-on-mesh
    _Pair(
      'light over terracotta patch',
      0xFF222222,
      overCream(0xFFC9684A, 0.3),
      4.5,
    ),
    _Pair('light over sage patch', 0xFF222222, overCream(0xFF8FA98A, 0.3), 4.5),
    _Pair(
      'light over butter patch',
      0xFF222222,
      overCream(0xFFF2CF66, 0.3),
      4.5,
    ),
    _Pair(
      'light over lavender mesh',
      0xFF222222,
      overCream(0xFFE7DEFA, 0.5),
      4.5,
    ),
    _Pair('light over peach mesh', 0xFF222222, overCream(0xFFFADFD0, 0.5), 4.5),
    _Pair('light over sage mesh', 0xFF222222, overCream(0xFFDDE8D6, 0.5), 4.5),
    _Pair(
      'light over butter mesh',
      0xFF222222,
      overCream(0xFFF7E7C4, 0.3),
      4.5,
    ),
    _Pair(
      'light inkMuted over lavender mesh',
      0xFF5C5A66,
      overCream(0xFFE7DEFA, 0.5),
      4.5,
    ),
    _Pair(
      'light inkMuted over peach mesh',
      0xFF5C5A66,
      overCream(0xFFFADFD0, 0.5),
      4.5,
    ),
    _Pair(
      'light inkMuted over sage mesh',
      0xFF5C5A66,
      overCream(0xFFDDE8D6, 0.5),
      4.5,
    ),
    _Pair(
      'light inkMuted over butter mesh',
      0xFF5C5A66,
      overCream(0xFFF7E7C4, 0.3),
      4.5,
    ),
    _Pair('light on glass/lavender', 0xFF222222, glassOver(0xFFE7DEFA), 4.5),
    _Pair('light on glass/peach', 0xFF222222, glassOver(0xFFFADFD0), 4.5),
    // Combined worst cases: patch ON TOP of the animated mesh.
    _Pair(
      'light ink over terracotta over sage mesh',
      0xFF222222,
      blend(0xFFC9684A, overCream(0xFFDDE8D6, 0.5), 0.3),
      4.5,
    ),
    _Pair(
      'light inkMuted over butter over lavender mesh',
      0xFF5C5A66,
      blend(0xFFF2CF66, overCream(0xFFE7DEFA, 0.5), 0.3),
      4.5,
    ),
    // ---- Light inside-node labels (white 600/12sp on gradient end = base)
    const _Pair('light node discover', 0xFFFFFFFF, 0xFF5B2EC7, 4.5),
    const _Pair('light node gigs', 0xFFFFFFFF, 0xFF0C6E54, 4.5),
    const _Pair('light node market', 0xFFFFFFFF, 0xFFB84A2E, 4.5),
    const _Pair('light node chats', 0xFFFFFFFF, 0xFF1D5FB0, 4.5),
    const _Pair('light node saved', 0xFFFFFFFF, 0xFF8F5C0C, 4.5),
    const _Pair('light node profile', 0xFFFFFFFF, 0xFF475467, 4.5),
    const _Pair('light node hub', 0xFFFFFFFF, 0xFF4A22A6, 4.5),
    for (final e in gradLight.entries)
      _Pair('light node ${e.key} gradient start', white, e.value, 4.5),
    // ---- Dark theme UI text
    const _Pair('dark ink/bg', 0xFFF3F0FB, 0xFF0F0B1A, 4.5),
    const _Pair('dark inkMuted/bg', 0xFFB2A9CC, 0xFF0F0B1A, 4.5),
    const _Pair('dark inkMuted/surface', 0xFFB2A9CC, 0xFF19132B, 4.5),
    const _Pair('dark primary/surface (links)', 0xFF9B7BFF, 0xFF19132B, 4.5),
    const _Pair(
      'dark onPrimary/primary (filled buttons)',
      0xFF12082E,
      0xFF9B7BFF,
      4.5,
    ),
    const _Pair(
      'dark brand Post pill (fixed accent)',
      0xFF12082E,
      0xFF9B7BFF,
      4.5,
    ),
    const _Pair('dark error/surface', 0xFFF0808C, 0xFF19132B, 4.5),
    const _Pair(
      'dark primary/surfaceRaised (secondary buttons)',
      0xFF9B7BFF,
      0xFF2A1F4D,
      4.5,
    ),
    // ---- Dark inverted pill (near-white fill, near-black label)
    const _Pair(
      'dark onPill/pill (ink CTA, selected chips)',
      0xFF17122B,
      0xFFF3F0FB,
      4.5,
    ),
    // ---- Dark ink system (dock = surfaceRaised + outline)
    const _Pair('dark onInk/dock (dock title)', 0xFFF3F0FB, 0xFF221A38, 4.5),
    _Pair('dark dock subtitle/dock', dockSubtitleDark, 0xFF221A38, 4.5),
    // ---- Dark tonal tiles (ink text on base @ 14% over surface)
    _Pair('dark tile discover', 0xFFF3F0FB, tileDark(0xFF9B7BFF), 4.5),
    _Pair('dark tile gigs', 0xFFF3F0FB, tileDark(0xFF3FC6A0), 4.5),
    _Pair('dark tile market', 0xFFF3F0FB, tileDark(0xFFF08A6A), 4.5),
    _Pair('dark tile chats', 0xFFF3F0FB, tileDark(0xFF5FA2F0), 4.5),
    _Pair('dark tile saved', 0xFFF3F0FB, tileDark(0xFFE3A94A), 4.5),
    _Pair('dark tile profile', 0xFFF3F0FB, tileDark(0xFF9AA6B8), 4.5),
    // ---- Dark text over the animated mesh worst case (meshAlphaDark 30%,
    // butter x0.6 -> 18%, over the dark background)
    _Pair(
      'dark ink over lavender mesh',
      0xFFF3F0FB,
      overDarkBg(0xFF2A1F4D, 0.3),
      4.5,
    ),
    _Pair(
      'dark ink over peach mesh',
      0xFFF3F0FB,
      overDarkBg(0xFF3A2230, 0.3),
      4.5,
    ),
    _Pair(
      'dark ink over sage mesh',
      0xFFF3F0FB,
      overDarkBg(0xFF1E2F2A, 0.3),
      4.5,
    ),
    _Pair(
      'dark ink over butter mesh',
      0xFFF3F0FB,
      overDarkBg(0xFF3A3020, 0.18),
      4.5,
    ),
    _Pair(
      'dark inkMuted over lavender mesh',
      0xFFB2A9CC,
      overDarkBg(0xFF2A1F4D, 0.3),
      4.5,
    ),
    _Pair(
      'dark inkMuted over peach mesh',
      0xFFB2A9CC,
      overDarkBg(0xFF3A2230, 0.3),
      4.5,
    ),
    _Pair(
      'dark inkMuted over sage mesh',
      0xFFB2A9CC,
      overDarkBg(0xFF1E2F2A, 0.3),
      4.5,
    ),
    _Pair(
      'dark inkMuted over butter mesh',
      0xFFB2A9CC,
      overDarkBg(0xFF3A3020, 0.18),
      4.5,
    ),
    // ---- Dark inside-node glyphs use onPrimary (#12082E) on the base hue
    const _Pair('dark node discover', 0xFF12082E, 0xFF9B7BFF, 4.5),
    const _Pair('dark node gigs', 0xFF12082E, 0xFF3FC6A0, 4.5),
    const _Pair('dark node market', 0xFF12082E, 0xFFF08A6A, 4.5),
    const _Pair('dark node chats', 0xFF12082E, 0xFF5FA2F0, 4.5),
    const _Pair('dark node saved', 0xFF12082E, 0xFFE3A94A, 4.5),
    const _Pair('dark node profile', 0xFF12082E, 0xFF9AA6B8, 4.5),
    const _Pair('dark node hub', 0xFFFFFFFF, 0xFF4A22A6, 4.5),
    for (final e in gradDark.entries)
      _Pair('dark node ${e.key} gradient start', 0xFF12082E, e.value, 4.5),
  ];
  var failures = 0;
  for (final p in pairs) {
    final r = ratio(p.fg, p.bg);
    final ok = r >= p.min;
    if (!ok) failures++;
    stdout.writeln(
      '${ok ? 'PASS' : 'FAIL'}  ${r.toStringAsFixed(2)}:1  (min ${p.min}:1)  ${p.name}',
    );
  }
  if (failures > 0) {
    stderr.writeln('$failures pair(s) below target.');
    exit(1);
  }
  stdout.writeln('All ${pairs.length} pairs meet their contrast target.');
}
