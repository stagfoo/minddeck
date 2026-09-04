/// The look: near-black ground, saturated cards, black text on colour.
///
/// Borrowed from the rabbitOS stack — the colour is the whole interface, so
/// everything around it stays out of the way.
library;

import 'package:flutter/material.dart';

import 'card_style.dart';

class DeckColors {
  static const ground = Color(0xFF08080A);
  static const strip = Color(0xFF101014);
  static const surface = Color(0xFF1A1A1F);
  static const surfaceEdge = Color(0xFF2A2A32);
  static const text = Color(0xFFF4F4F7);
  static const textDim = Color(0xFF83838F);

  /// Text and glyphs sitting on a card. The palette is chosen so black always
  /// reads, which is what keeps the stack looking like one thing.
  static const onCard = Color(0xFF0A0A0C);
}

class DeckMetrics {
  /// The action row along the bottom. Slim: it is two icons, and every pixel
  /// it takes is one the deck does not get.
  static const actionsHeight = 40.0;
  /// The full right band is the scrub area — a thin track would be a hairline
  /// target on a screen this small. The visible parts sit inside it.
  static const railWidth = 52.0;
  static const gutter = 12.0;
  static const cardRadius = 14.0;
}

Color colorOf(String key) => Color(colorForKey(key).value);

/// Glyph for a stored icon key. The model holds keys, not Flutter types, so
/// this is the one place the two vocabularies meet.
IconData iconOf(String key) {
  switch (normaliseIconKey(key)) {
    case 'apps':
      return Icons.grid_view_rounded;
    case 'camera':
      return Icons.photo_camera_rounded;
    case 'music':
      return Icons.music_note_rounded;
    case 'photo':
      return Icons.image_rounded;
    case 'chat':
      return Icons.chat_bubble_rounded;
    case 'globe':
      return Icons.public_rounded;
    case 'game':
      return Icons.sports_esports_rounded;
    case 'book':
      return Icons.menu_book_rounded;
    case 'map':
      return Icons.map_rounded;
    case 'clock':
      return Icons.schedule_rounded;
    case 'heart':
      return Icons.favorite_rounded;
    case 'star':
      return Icons.star_rounded;
    case 'bolt':
      return Icons.bolt_rounded;
    case 'cog':
      return Icons.settings_rounded;
    case 'wallet':
      return Icons.account_balance_wallet_rounded;
    case 'note':
      return Icons.sticky_note_2_rounded;
    case 'tools':
      return Icons.build_rounded;
    default:
      return Icons.folder_rounded;
  }
}

/// Text in Lexend at a given weight.
///
/// Lexend ships as one variable font with a wght axis. Measured on this engine,
/// [TextStyle.fontWeight] alone does drive that axis — identical advance widths
/// to setting [FontVariation] explicitly — so this is not working around a bug.
/// Both are set anyway: the axis is then stated outright rather than depending
/// on that mapping continuing to hold, and fontWeight keeps fallback fonts and
/// any synthetic bolding honest. font_test.dart measures real widths, so if the
/// mapping ever changes it fails rather than silently flattening every weight.
TextStyle deckText({
  required double size,
  int weight = 400,
  Color color = DeckColors.text,
  double? letterSpacing,
  double? height,
}) {
  return TextStyle(
    fontFamily: 'Lexend',
    fontSize: size,
    color: color,
    fontWeight: FontWeight.values.firstWhere(
      (candidate) => candidate.value == weight,
      orElse: () => FontWeight.normal,
    ),
    fontVariations: [FontVariation('wght', weight.toDouble())],
    letterSpacing: letterSpacing,
    height: height,
  );
}

ThemeData buildDeckTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: DeckColors.ground,
    colorScheme: const ColorScheme.dark(
      surface: DeckColors.ground,
      primary: Color(0xFFFF4F00),
      onPrimary: DeckColors.onCard,
    ),
    fontFamily: 'Lexend',
    textTheme: const TextTheme().apply(
      fontFamily: 'Lexend',
      bodyColor: DeckColors.text,
      displayColor: DeckColors.text,
    ),
  );
}
