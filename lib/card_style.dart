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

/// Icon identities, stored as keys so the model never holds a Flutter type.
/// The widget layer maps these to real glyphs.
const List<String> cardIconKeys = [
  'apps',
  'camera',
  'music',
  'photo',
  'chat',
  'globe',
  'game',
  'book',
  'map',
  'clock',
  'heart',
  'star',
  'bolt',
  'cog',
  'folder',
  'wallet',
  'note',
  'tools',
];

const String fallbackIconKey = 'folder';

/// The colour for [key], falling back to the first entry rather than throwing:
/// a stored deck from an older palette must still open.
CardColor colorForKey(String key) {
  for (final color in cardPalette) {
    if (color.key == key) return color;
  }
  return cardPalette.first;
}

bool isKnownColorKey(String key) => cardPalette.any((color) => color.key == key);

/// Normalises an icon key, so a deck written by a future version with icons
/// this build doesn't have still renders something sensible.
String normaliseIconKey(String? key) =>
    key != null && cardIconKeys.contains(key) ? key : fallbackIconKey;

/// The colour a card gets when it is created and nobody has picked one, walking
/// the palette so a fresh deck is not eight magenta cards.
CardColor paletteAt(int index) =>
    cardPalette[index.abs() % cardPalette.length];
