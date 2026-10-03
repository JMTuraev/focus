import 'package:flutter/widgets.dart';

/// Window-width layouts, modelled on Telegram Desktop.
enum LayoutMode {
  /// Rail, chat list, chat and a docked info column.
  wide,

  /// Rail, chat list and chat; the info panel slides over the chat.
  medium,

  /// One column: the chat list, or the open chat with a back button.
  narrow,
}

class Breakpoints {
  static const double wide = 1200;
  static const double narrow = 800;

  static LayoutMode of(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= wide) return LayoutMode.wide;
    if (w >= narrow) return LayoutMode.medium;
    return LayoutMode.narrow;
  }
}
