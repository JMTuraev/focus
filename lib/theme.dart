import 'package:flutter/material.dart';

/// Fokus palette, light and dark (Telegram "Night"-like) variants.
///
/// Read colors in widgets with `final c = context.fc;`.
/// - [accent] `#3390EC`: icons, strokes, non-text accents.
/// - [accentStrong] `#2874C8`: fills under white text.
/// - [accentText]: links and accent-colored text on panels
///   (`#2874C8` in light mode, a lighter blue in dark mode for contrast).
@immutable
class FokusColors extends ThemeExtension<FokusColors> {
  const FokusColors({
    required this.accent,
    required this.accentStrong,
    required this.accentText,
    required this.accentSoft,
    required this.bg,
    required this.panel,
    required this.titleBar,
    required this.border,
    required this.text,
    required this.text2,
    required this.textSoft,
    required this.icon,
    required this.hover,
    required this.railHover,
    required this.winHover,
    required this.chipBorder,
    required this.waiting,
    required this.waitingStrong,
    required this.inBubble,
    required this.outBubble,
    required this.outMeta,
    required this.bubbleShadow,
    required this.wallpaper,
    required this.wallDotLight,
    required this.wallDotDark,
    required this.datePill,
    required this.meetingBg,
    required this.qaBg,
    required this.qaHover,
    required this.qaBorder,
    required this.qaFg,
    required this.tagActiveBorder,
    required this.localBg,
    required this.localFg,
    required this.online,
    required this.muted,
    required this.toast,
  });

  /// Brand color, the same in both modes (logo).
  static const brand = Color(0xFF3390EC);

  final Color accent;
  final Color accentStrong;
  final Color accentText;
  final Color accentSoft;
  final Color bg;
  final Color panel;
  final Color titleBar;
  final Color border;
  final Color text;
  final Color text2;
  final Color textSoft;
  final Color icon;
  final Color hover;
  final Color railHover;
  final Color winHover;
  final Color chipBorder;
  final Color waiting;
  final Color waitingStrong;
  final Color inBubble;
  final Color outBubble;
  final Color outMeta;
  final Color bubbleShadow;
  final Color wallpaper;
  final Color wallDotLight;
  final Color wallDotDark;
  final Color datePill;
  final Color meetingBg;
  final Color qaBg;
  final Color qaHover;
  final Color qaBorder;
  final Color qaFg;
  final Color tagActiveBorder;
  final Color localBg;
  final Color localFg;
  final Color online;
  final Color muted;
  final Color toast;

  static const light = FokusColors(
    accent: Color(0xFF3390EC),
    accentStrong: Color(0xFF2874C8),
    accentText: Color(0xFF2874C8),
    accentSoft: Color(0xFFE4EFFB),
    bg: Color(0xFFF1F3F5),
    panel: Colors.white,
    titleBar: Color(0xFFF7F8FA),
    border: Color(0xFFE2E4E7),
    text: Color(0xFF1B1F24),
    text2: Color(0xFF646B72),
    textSoft: Color(0xFF3A4048),
    icon: Color(0xFF5F666D),
    hover: Color(0xFFF2F4F6),
    railHover: Color(0xFFEEF1F4),
    winHover: Color(0xFFE6E8EB),
    chipBorder: Color(0xFFDDE1E6),
    waiting: Color(0xFFE8860C),
    waitingStrong: Color(0xFFB35A00),
    inBubble: Colors.white,
    outBubble: Color(0xFFE3F6CF),
    outMeta: Color(0xFF3B7529),
    bubbleShadow: Color(0x24203214),
    wallpaper: Color(0xFFD3E2C1),
    wallDotLight: Color(0x80FFFFFF),
    wallDotDark: Color(0x21466E32),
    datePill: Color(0x6B283C1E),
    meetingBg: Color(0xF0FFFFFF),
    qaBg: Color(0xFFF3F8FE),
    qaHover: Color(0xFFE1EDFB),
    qaBorder: Color(0xFFCFE0F3),
    qaFg: Color(0xFF1E5FA6),
    tagActiveBorder: Color(0xFF9CC2EC),
    localBg: Color(0xFFE2F4E6),
    localFg: Color(0xFF17692F),
    online: Color(0xFF2DB24A),
    muted: Color(0xFF6F767E),
    toast: Color(0xFF1F2A36),
  );

  static const dark = FokusColors(
    accent: Color(0xFF3390EC),
    accentStrong: Color(0xFF2874C8),
    accentText: Color(0xFF6AB2F2),
    accentSoft: Color(0xFF1F3550),
    bg: Color(0xFF0E1621),
    panel: Color(0xFF17212B),
    titleBar: Color(0xFF131C25),
    border: Color(0xFF0F1922),
    text: Color(0xFFF1F4F7),
    text2: Color(0xFF8193A5),
    textSoft: Color(0xFFC5CFD9),
    icon: Color(0xFF8A9AAB),
    hover: Color(0xFF202B36),
    railHover: Color(0xFF202B36),
    winHover: Color(0xFF26323E),
    chipBorder: Color(0xFF2A3744),
    waiting: Color(0xFFF0962A),
    waitingStrong: Color(0xFFB35A00),
    inBubble: Color(0xFF182533),
    outBubble: Color(0xFF2B5278),
    outMeta: Color(0xFF8DB8E2),
    bubbleShadow: Color(0x33000000),
    wallpaper: Color(0xFF0E1621),
    wallDotLight: Color(0x0DFFFFFF),
    wallDotDark: Color(0x1A3390EC),
    datePill: Color(0x991E2C3A),
    meetingBg: Color(0xF0182533),
    qaBg: Color(0xFF1B2B3B),
    qaHover: Color(0xFF223649),
    qaBorder: Color(0xFF2A4560),
    qaFg: Color(0xFF7FB8F0),
    tagActiveBorder: Color(0xFF3A6A9A),
    localBg: Color(0xFF1C3B26),
    localFg: Color(0xFF7BD88F),
    online: Color(0xFF3CC75A),
    muted: Color(0xFF56636F),
    toast: Color(0xFF2B3946),
  );

  @override
  FokusColors copyWith() => this;

  @override
  FokusColors lerp(FokusColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    final o = other;
    return FokusColors(
      accent: l(accent, o.accent),
      accentStrong: l(accentStrong, o.accentStrong),
      accentText: l(accentText, o.accentText),
      accentSoft: l(accentSoft, o.accentSoft),
      bg: l(bg, o.bg),
      panel: l(panel, o.panel),
      titleBar: l(titleBar, o.titleBar),
      border: l(border, o.border),
      text: l(text, o.text),
      text2: l(text2, o.text2),
      textSoft: l(textSoft, o.textSoft),
      icon: l(icon, o.icon),
      hover: l(hover, o.hover),
      railHover: l(railHover, o.railHover),
      winHover: l(winHover, o.winHover),
      chipBorder: l(chipBorder, o.chipBorder),
      waiting: l(waiting, o.waiting),
      waitingStrong: l(waitingStrong, o.waitingStrong),
      inBubble: l(inBubble, o.inBubble),
      outBubble: l(outBubble, o.outBubble),
      outMeta: l(outMeta, o.outMeta),
      bubbleShadow: l(bubbleShadow, o.bubbleShadow),
      wallpaper: l(wallpaper, o.wallpaper),
      wallDotLight: l(wallDotLight, o.wallDotLight),
      wallDotDark: l(wallDotDark, o.wallDotDark),
      datePill: l(datePill, o.datePill),
      meetingBg: l(meetingBg, o.meetingBg),
      qaBg: l(qaBg, o.qaBg),
      qaHover: l(qaHover, o.qaHover),
      qaBorder: l(qaBorder, o.qaBorder),
      qaFg: l(qaFg, o.qaFg),
      tagActiveBorder: l(tagActiveBorder, o.tagActiveBorder),
      localBg: l(localBg, o.localBg),
      localFg: l(localFg, o.localFg),
      online: l(online, o.online),
      muted: l(muted, o.muted),
      toast: l(toast, o.toast),
    );
  }
}

extension FokusColorsX on BuildContext {
  FokusColors get fc => Theme.of(this).extension<FokusColors>()!;
}

ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? FokusColors.dark : FokusColors.light;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: 'Segoe UI',
    scaffoldBackgroundColor: c.bg,
    splashFactory: NoSplash.splashFactory,
    colorScheme: ColorScheme.fromSeed(
      seedColor: FokusColors.brand,
      brightness: brightness,
      primary: c.accentStrong,
      surface: c.panel,
      onSurface: c.text,
    ),
    dividerColor: c.border,
    textSelectionTheme: TextSelectionThemeData(cursorColor: c.accentText),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.toast,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      actionTextColor: const Color(0xFF9FCBFF),
    ),
    extensions: [c],
  );
}
