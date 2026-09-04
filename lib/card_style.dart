/// The palette and icon set a card can be given.
///
/// Both are closed sets on purpose. A launcher whose cards can be any colour
/// ends up looking like a spreadsheet; the rabbit-ish look comes from a small
/// number of saturated, high-contrast colours that always take black text.
///
/// Pure Dart — no Flutter — so the catalogue and the rules about it are
/// testable, and the model can store a colour as an int and an icon as a key
/// without dragging widgets into it.
library;

import 'icon_catalogue.dart';

class CardColor {
  const CardColor(this.key, this.name, this.value);

  final String key;
  final String name;

  /// Opaque ARGB.
  final int value;
}

/// Saturated flat colours that all carry black text legibly — the rabbitOS
/// stack look. Ordered so consecutive cards land on visibly different hues
/// when a deck is seeded.
const List<CardColor> cardPalette = [
  CardColor('magenta', 'Magenta', 0xFFFF2BB5),
  CardColor('cyan', 'Cyan', 0xFF3FE3F0),
  CardColor('periwinkle', 'Periwinkle', 0xFF8E8CF8),
  CardColor('green', 'Green', 0xFF2BE04B),
  CardColor('red', 'Red', 0xFFFF3123),
  CardColor('orange', 'Orange', 0xFFFF9A0E),
  CardColor('blue', 'Blue', 0xFF37A8FF),
  CardColor('violet', 'Violet', 0xFFC57DFF),
  CardColor('lime', 'Lime', 0xFFC8F02B),
  CardColor('coral', 'Coral', 0xFFFF6B5A),
  CardColor('mint', 'Mint', 0xFF4FE8B0),
  CardColor('butter', 'Butter', 0xFFFFD93D),
];

/// The icons offered up front in the card editor, before searching.
///
/// Every Material icon is available — see [materialIcons], all 2,200 of them —
/// but a wall of two thousand is not a choice, it is a search problem. These
/// are the ones a folder of apps is usually about, so the common case is a tap
/// rather than a query.
const List<String> popularIconKeys = [
  'grid_view',
  'star',
  'favorite',
  'music_note',
  'photo_camera',
  'image',
  'movie',
  'sports_esports',
  'chat_bubble',
  'call',
  'mail',
  'public',
  'menu_book',
  'map',
  'schedule',
  'alarm',
  'shopping_bag',
  'account_balance_wallet',
  'work',
  'school',
  'fitness_center',
  'restaurant',
  'directions_car',
  'flight',
  'build',
  'settings',
  'code',
  'terminal',
  'cloud',
  'lock',
  'sticky_note_2',
  'checklist',
  'bolt',
  'lightbulb',
  'palette',
  'folder',
];

const String fallbackIconKey = 'folder';

/// Keys written by the first builds, which used names of their own invention
/// rather than Material's. Kept so a card saved then keeps its icon.
const Map<String, String> legacyIconKeys = {
  'apps': 'grid_view',
  'camera': 'photo_camera',
  'music': 'music_note',
  'photo': 'image',
  'chat': 'chat_bubble',
  'globe': 'public',
  'game': 'sports_esports',
  'book': 'menu_book',
  'clock': 'schedule',
  'heart': 'favorite',
  'cog': 'settings',
  'wallet': 'account_balance_wallet',
  'note': 'sticky_note_2',
  'tools': 'build',
};

/// The colour for [key], falling back to the first entry rather than throwing:
/// a stored deck from an older palette must still open.
CardColor colorForKey(String key) {
  for (final color in cardPalette) {
    if (color.key == key) return color;
  }
  return cardPalette.first;
}

bool isKnownColorKey(String key) => cardPalette.any((color) => color.key == key);

/// Normalises an icon key: translates a legacy name, accepts anything in the
/// catalogue, and falls back for anything else — so a deck written by a future
/// version with icons this build does not have still renders something.
String normaliseIconKey(String? key) {
  if (key == null) return fallbackIconKey;
  final translated = legacyIconKeys[key] ?? key;
  return materialIcons.containsKey(translated) ? translated : fallbackIconKey;
}

/// Icons whose name contains [query], for the picker's search.
List<String> searchIcons(String query) {
  final needle = query.trim().toLowerCase().replaceAll(' ', '_');
  if (needle.isEmpty) return popularIconKeys;
  return [
    for (final key in materialIcons.keys)
      if (key.contains(needle)) key,
  ];
}

/// The colour a card gets when it is created and nobody has picked one, walking
/// the palette so a fresh deck is not eight magenta cards.
CardColor paletteAt(int index) =>
    cardPalette[index.abs() % cardPalette.length];
