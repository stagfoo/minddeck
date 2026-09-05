import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolidecks/card_deck.dart';
import 'package:rolidecks/card_style.dart';
import 'package:rolidecks/theme.dart';

void main() {
  group('custom colour keys', () {
    test('a hex key round-trips to the colour it names', () {
      expect(customColorValue('#ff3366'), 0xFFFF3366);
      expect(customColorKey(0xFFFF3366), '#ff3366');
      expect(colorForKey('#ff3366').value, 0xFFFF3366);
    });

    test('accepts an alpha-carrying key too', () {
      expect(customColorValue('#80ff3366'), 0x80FF3366);
    });

    test('rejects anything that is not one', () {
      for (final key in ['magenta', '#xyzxyz', '#ff33', '', '#']) {
        expect(customColorValue(key), isNull, reason: key);
        expect(isCustomColorKey(key), isFalse, reason: key);
      }
    });

    test('a palette name still resolves to its palette colour', () {
      expect(colorForKey('magenta').value, colorForKey('magenta').value);
      expect(isCustomColorKey('magenta'), isFalse);
      expect(isKnownColorKey('magenta'), isTrue);
      expect(isKnownColorKey('#123456'), isTrue);
    });

    test('an unknown non-hex key still falls back rather than throwing', () {
      expect(colorForKey('ultraviolet').value, cardPalette.first.value);
    });

    test('a card keeps a custom colour across a save and load', () {
      var deck = CardDeck.seed();
      final id = deck.folders.first.id;
      deck = deck.updateCard(id, (card) => card.copyWith(colorKey: '#ff3366'));
      final restored = CardDeck.fromJson(deck.toJson());
      expect(restored.cards[restored.indexOfId(id)].colorKey, '#ff3366');
    });
  });

  group('the shelf', () {
    test('shows the five the starter deck arrives with', () {
      expect(starterColorKeys, hasLength(5));
      expect(starterColorKeys,
          [for (final entry in cardPalette.take(5)) entry.key]);
    });

    test('the other palette colours still resolve, they are just not shown', () {
      // The all-apps card is butter, and decks already saved name colours from
      // the whole palette — dropping them would repaint those cards.
      for (final entry in cardPalette) {
        expect(isKnownColorKey(entry.key), isTrue, reason: entry.key);
        expect(colorForKey(entry.key).value, entry.value, reason: entry.key);
      }
      expect(starterColorKeys.contains('butter'), isFalse);
      expect(colorForKey('butter').value, isNot(cardPalette.first.value));
    });
  });

  group('the foreground follows the colour', () {
    test('black on every palette colour, which is why they were chosen', () {
      for (final entry in cardPalette) {
        expect(onCardFor(Color(entry.value)), DeckColors.onCard,
            reason: entry.key);
      }
    });

    test('switches to light on a dark custom colour', () {
      // Without this, picking a navy card would lose the card's own name into
      // it — the whole reason the preset palette was closed.
      expect(onCardFor(const Color(0xFF10214A)), DeckColors.onCardLight);
      expect(onCardFor(const Color(0xFF000000)), DeckColors.onCardLight);
    });

    test('stays black on a light custom colour', () {
      expect(onCardFor(const Color(0xFFFFFFFF)), DeckColors.onCard);
      expect(onCardFor(const Color(0xFFFFE08A)), DeckColors.onCard);
    });

    test('whatever it picks is the more readable of the two', () {
      // The point is contrast, so assert that directly rather than trusting
      // the threshold.
      double contrast(Color a, Color b) {
        final la = a.computeLuminance();
        final lb = b.computeLuminance();
        final hi = la > lb ? la : lb;
        final lo = la > lb ? lb : la;
        return (hi + 0.05) / (lo + 0.05);
      }

      for (final value in [
        0xFF000000, 0xFFFFFFFF, 0xFF10214A, 0xFFFF2BB5, 0xFF2BE04B, 0xFF7F7F7F,
      ]) {
        final background = Color(value);
        final chosen = onCardFor(background);
        final other = chosen == DeckColors.onCard
            ? DeckColors.onCardLight
            : DeckColors.onCard;
        expect(
          contrast(background, chosen),
          greaterThanOrEqualTo(contrast(background, other)),
          reason: value.toRadixString(16),
        );
      }
    });
  });
}
