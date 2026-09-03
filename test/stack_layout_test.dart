import 'package:flutter_test/flutter_test.dart';
import 'package:minddeck/stack_layout.dart';

void main() {
  // The Mind One in portrait: 1080 × 1240 physical, about 393 × 451 dp at a
  // 2.75 density. The stack gets what's left under the clock strip.
  const stackHeight = 390.0;

  group('solveStack on the Mind One panel', () {
    test('fits a six-card deck without overflowing', () {
      final spec = solveStack(height: stackHeight, cardCount: 6, focusedIndex: 0);
      expect(spec.totalHeight, lessThanOrEqualTo(stackHeight + 0.01));
      expect(spec.peek, greaterThanOrEqualTo(StackStyle.standard.minPeek));
    });

    test('the open card is much taller than a collapsed sliver', () {
      final spec = solveStack(height: stackHeight, cardCount: 6, focusedIndex: 2);
      expect(spec.heightOf(2), spec.focusedHeight);
      expect(spec.heightOf(0), spec.peek);
      expect(spec.focusedHeight, greaterThan(spec.peek * 2));
    });

    test('cards never overlap: each starts where the last one ends', () {
      final spec = solveStack(height: stackHeight, cardCount: 6, focusedIndex: 3);
      for (var i = 1; i < spec.cardCount; i++) {
        expect(
          spec.topOf(i),
          closeTo(spec.topOf(i - 1) + spec.heightOf(i - 1), 0.01),
          reason: 'card $i should follow card ${i - 1}',
        );
      }
    });

    test('the last card ends inside the box', () {
      final spec = solveStack(height: stackHeight, cardCount: 8, focusedIndex: 7);
      final last = spec.cardCount - 1;
      expect(spec.topOf(last) + spec.heightOf(last),
          lessThanOrEqualTo(stackHeight + 0.01));
    });

    test('holds together wherever focus is', () {
      for (var focus = 0; focus < 8; focus++) {
        final spec = solveStack(height: stackHeight, cardCount: 8, focusedIndex: focus);
        expect(spec.totalHeight, lessThanOrEqualTo(stackHeight + 0.01),
            reason: 'focus $focus');
        expect(spec.topOf(0), greaterThanOrEqualTo(-0.01), reason: 'focus $focus');
      }
    });

    test('a short deck is centred rather than pinned to the top', () {
      final spec = solveStack(height: stackHeight, cardCount: 2, focusedIndex: 0);
      expect(spec.originY, greaterThan(0));
      expect(spec.originY, closeTo((stackHeight - spec.totalHeight) / 2, 0.01));
    });

    test('a crowded deck keeps slivers readable, shrinking the open card', () {
      // Twenty cards can't all have a comfortable sliver; better a smaller open
      // card than slivers too thin to read.
      final spec = solveStack(height: stackHeight, cardCount: 20, focusedIndex: 0);
      expect(spec.peek, greaterThanOrEqualTo(StackStyle.standard.minPeek - 0.01));
      expect(spec.focusedHeight,
          greaterThanOrEqualTo(StackStyle.standard.minFocusedHeight - 0.01));
    });
  });

  group('solveStack edges', () {
    test('an empty deck produces no height and does not divide by zero', () {
      final spec = solveStack(height: stackHeight, cardCount: 0, focusedIndex: 0);
      expect(spec.totalHeight, 0);
    });

    test('a single card fills as the open card', () {
      final spec = solveStack(height: stackHeight, cardCount: 1, focusedIndex: 0);
      expect(spec.totalHeight, spec.focusedHeight);
      expect(spec.heightOf(0), spec.focusedHeight);
    });

    test('an out-of-range focus is clamped, not thrown', () {
      expect(solveStack(height: stackHeight, cardCount: 4, focusedIndex: 99).focusedIndex, 3);
      expect(solveStack(height: stackHeight, cardCount: 4, focusedIndex: -3).focusedIndex, 0);
    });

    test('a zero-height box still yields positive card heights', () {
      final spec = solveStack(height: 0, cardCount: 5, focusedIndex: 0);
      expect(spec.peek, greaterThan(0));
      expect(spec.focusedHeight, greaterThan(0));
    });
  });

  group('solveKnob', () {
    const track = 340.0;

    test('sits at the top for the first card and the bottom for the last', () {
      final first = solveKnob(trackHeight: track, cardCount: 6, focusedIndex: 0);
      final last = solveKnob(trackHeight: track, cardCount: 6, focusedIndex: 5);
      expect(first.top, 0);
      expect(last.top + last.height, closeTo(track, 0.01));
    });

    test('shrinks as the deck grows, like a scrollbar thumb', () {
      final few = solveKnob(trackHeight: track, cardCount: 3, focusedIndex: 0);
      final many = solveKnob(trackHeight: track, cardCount: 12, focusedIndex: 0);
      expect(many.height, lessThan(few.height));
    });

    test('never shrinks below a grabbable size', () {
      final knob = solveKnob(trackHeight: track, cardCount: 200, focusedIndex: 0);
      expect(knob.height, greaterThanOrEqualTo(44));
    });

    test('stays on the track at every position', () {
      for (var i = 0; i < 9; i++) {
        final knob = solveKnob(trackHeight: track, cardCount: 9, focusedIndex: i);
        expect(knob.top, greaterThanOrEqualTo(-0.01), reason: 'card $i');
        expect(knob.top + knob.height, lessThanOrEqualTo(track + 0.01),
            reason: 'card $i');
      }
    });

    test('a one-card deck fills the track rather than leaving a stub', () {
      final knob = solveKnob(trackHeight: track, cardCount: 1, focusedIndex: 0);
      expect(knob.height, track);
    });
  });

  group('cardIndexForKnobPosition', () {
    const track = 340.0;

    test('dragging to the ends selects the first and last card', () {
      expect(cardIndexForKnobPosition(y: 0, trackHeight: track, cardCount: 6), 0);
      expect(cardIndexForKnobPosition(y: track, trackHeight: track, cardCount: 6), 5);
    });

    test('is the inverse of solveKnob, so the grip lands under the finger', () {
      // Round-tripping matters: if these disagree the knob jumps away from the
      // finger mid-drag, which feels broken even when the selection is right.
      for (var i = 0; i < 7; i++) {
        final knob = solveKnob(trackHeight: track, cardCount: 7, focusedIndex: i);
        expect(
          cardIndexForKnobPosition(
            y: knob.center,
            trackHeight: track,
            cardCount: 7,
          ),
          i,
          reason: 'card $i',
        );
      }
    });

    test('a drag beyond the track clamps to a real card', () {
      expect(cardIndexForKnobPosition(y: -500, trackHeight: track, cardCount: 5), 0);
      expect(cardIndexForKnobPosition(y: 5000, trackHeight: track, cardCount: 5), 4);
    });

    test('a single-card deck always answers zero', () {
      expect(cardIndexForKnobPosition(y: 200, trackHeight: track, cardCount: 1), 0);
    });
  });
}
