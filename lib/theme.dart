import 'package:flutter/material.dart';

/// Palette from the Fokus prototype.
class FC {
  static const accent = Color(0xFF3390EC); // icons, strokes, non-text accents
  static const accentStrong = Color(0xFF2874C8); // fills under white text, links
  static const accentSoft = Color(0xFFE4EFFB);
  static const bg = Color(0xFFF1F3F5);
  static const panel = Colors.white;
  static const border = Color(0xFFE2E4E7);
  static const text = Color(0xFF1B1F24);
  static const text2 = Color(0xFF646B72);
  static const icon = Color(0xFF5F666D);
  static const hover = Color(0xFFF2F4F6);
  static const waiting = Color(0xFFE8860C);
  static const waitingStrong = Color(0xFFB35A00);
  static const outBubble = Color(0xFFE3F6CF);
  static const outMeta = Color(0xFF3B7529);
  static const wallpaper = Color(0xFFD3E2C1);
  static const localBg = Color(0xFFE2F4E6);
  static const localFg = Color(0xFF17692F);
  static const online = Color(0xFF2DB24A);
  static const muted = Color(0xFF6F767E);
  static const toast = Color(0xFF1F2A36);
}

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Segoe UI',
    scaffoldBackgroundColor: FC.bg,
    splashFactory: NoSplash.splashFactory,
    colorScheme: ColorScheme.fromSeed(
      seedColor: FC.accent,
      primary: FC.accentStrong,
      surface: FC.panel,
    ),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: FC.accentStrong),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: FC.toast,
      actionTextColor: Color(0xFF9FCBFF),
    ),
  );
}
