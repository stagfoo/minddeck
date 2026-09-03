/// The Switch's home screen look, adapted.
///
/// Nintendo's dark theme is a near-black ground with slightly lighter cards, a
/// thin top strip, and a bright cyan-white rim on whatever is selected. That
/// last part is the whole identity — everything else is restraint.
library;

import 'package:flutter/material.dart';

class DeckColors {
  static const ground = Color(0xFF1B1B1F);
  static const strip = Color(0xFF141417);
  static const card = Color(0xFF2C2C33);
  static const cardEdge = Color(0xFF3A3A43);
  static const selection = Color(0xFF00D2E6);
  static const text = Color(0xFFF2F2F5);
  static const textDim = Color(0xFF9A9AA5);
}

class DeckMetrics {
  /// The strip carrying the clock and battery.
  static const stripHeight = 44.0;

  /// The system-button row along the bottom, the Switch's News/eShop/Settings
  /// bar.
  static const systemRowHeight = 56.0;

  static const deckPadding = 16.0;
  static const tileRadius = 14.0;
}

ThemeData buildDeckTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: DeckColors.ground,
    colorScheme: const ColorScheme.dark(
      surface: DeckColors.ground,
      primary: DeckColors.selection,
      onPrimary: Color(0xFF06212A),
      secondary: DeckColors.card,
    ),
    textTheme: const TextTheme().apply(
      bodyColor: DeckColors.text,
      displayColor: DeckColors.text,
    ),
  );
}
