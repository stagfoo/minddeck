import 'package:flutter_test/flutter_test.dart';
import 'package:minddeck/card_deck.dart';
import 'package:minddeck/stack_layout.dart';

/// Reproduces what the drag handler does: probe the middle of the dragged
/// card's own strip, clamp to the folders, and reorder.
CardDeck dragTo(CardDeck deck, ArrangeSpec spec, String cardId, double top) {
  final over = spec.indexForY(top + spec.cardHeight - spec.peek / 2);
  final folders = deck.folders;
  final from = folders.indexWhere((entry) => entry.id == cardId);
  final target = over.clamp(0, folders.length - 1);
  if (from < 0 || target == from) return deck;
  return deck.reorder(from, target);
}

void main() {
  const stackHeight = 390.0;

  group('dragging a card', () {
    test('dropping it on another row puts it there', () {
      final deck = CardDeck.seed();
      final spec =
          solveArrangeStack(height: stackHeight, cardCount: deck.length);
      final moved = deck.folders.first.id;

      final after = dragTo(deck, spec, moved, spec.topOf(3));
      expect(after.folders[3].id, moved);
    });

    test('a card dropped back where it started does not move', () {
      final deck = CardDeck.seed();
      final spec =
          solveArrangeStack(height: stackHeight, cardCount: deck.length);
      final id = deck.folders[2].id;
      final after = dragTo(deck, spec, id, spec.topOf(2));
      expect(after.folders.map((c) => c.id), deck.folders.map((c) => c.id));
    });

    test('never loses or duplicates a card, wherever it is dropped', () {
      final deck = CardDeck.seed();
      final spec =
          solveArrangeStack(height: stackHeight, cardCount: deck.length);
      final ids = deck.folders.map((c) => c.id).toSet();
      for (final card in deck.folders) {
        for (var slot = -2; slot < deck.length + 2; slot++) {
          final after = dragTo(deck, spec, card.id, spec.topOf(slot));
          expect(after.folders.map((c) => c.id).toSet(), ids,
              reason: '${card.name} -> $slot');
          expect(after.folders, hasLength(ids.length),
              reason: '${card.name} -> $slot');
        }
      }
    });
  });

  group('all apps holds the back of the deck', () {
    test('a card dragged past the end stops in front of it', () {
      // The all-apps card is the last row. Dragging a folder onto or beyond it
      // must land in the last folder slot, never behind it.
      final deck = CardDeck.seed();
      final spec =
          solveArrangeStack(height: stackHeight, cardCount: deck.length);
      final moved = deck.folders.first.id;

      final after = dragTo(deck, spec, moved, spec.topOf(deck.length + 5));
      expect(after.cards.last.isAllApps, isTrue);
      expect(after.folders.last.id, moved);
    });

    test('dragging onto the all-apps row itself is still clamped', () {
      final deck = CardDeck.seed();
      final spec =
          solveArrangeStack(height: stackHeight, cardCount: deck.length);
      final moved = deck.folders.first.id;

      final after = dragTo(deck, spec, moved, spec.topOf(deck.length - 1));
      expect(after.cards.last.isAllApps, isTrue);
      expect(after.folders.last.id, moved);
    });

    test('it is always the last card after any drag', () {
      var deck = CardDeck.seed();
      final spec =
          solveArrangeStack(height: stackHeight, cardCount: deck.length);
      for (var slot = 0; slot < deck.length + 3; slot++) {
        deck = dragTo(deck, spec, deck.folders.first.id, spec.topOf(slot));
        expect(deck.cards.last.isAllApps, isTrue, reason: 'slot $slot');
      }
    });
  });

  group('a live drag', () {
    test('walking a card down one row at a time ends where it was aimed', () {
      // The handler reorders continuously as the finger crosses rows, so the
      // deck has to survive being reordered on every frame of a drag.
      var deck = CardDeck.seed();
      final spec =
          solveArrangeStack(height: stackHeight, cardCount: deck.length);
      final moved = deck.folders.first.id;
      final ids = deck.folders.map((c) => c.id).toSet();

      var top = spec.topOf(0);
      for (var step = 0; step < 60; step++) {
        top += spec.peek / 6;
        deck = dragTo(deck, spec, moved, top);
        expect(deck.folders.map((c) => c.id).toSet(), ids, reason: 'step $step');
      }
      expect(deck.folders.last.id, moved);
    });
  });
}
