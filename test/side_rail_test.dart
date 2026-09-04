import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minddeck/card_style.dart';
import 'package:minddeck/side_rail.dart';
import 'package:minddeck/stack_layout.dart';
import 'package:minddeck/theme.dart';

Future<void> pump(
  WidgetTester tester, {
  required Color color,
  int cardCount = 6,
  int focusedIndex = 0,
  ValueChanged<int>? onFocusChanged,
}) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SizedBox(
        height: 400,
        child: SideRail(
          cardCount: cardCount,
          focusedIndex: focusedIndex,
          color: color,
          onFocusChanged: onFocusChanged ?? (_) {},
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

/// The grip is the innermost animated box on the rail; the track behind it is
/// a plain Container.
Color knobColor(WidgetTester tester) {
  final knob = tester.widget<AnimatedContainer>(
    find.byType(AnimatedContainer).last,
  );
  return (knob.decoration! as BoxDecoration).color!;
}

void main() {
  group('the grip wears the focused card colour', () {
    testWidgets('so the rail says which card you are on', (tester) async {
      await pump(tester, color: colorOf('magenta'));
      expect(knobColor(tester), colorOf('magenta'));
    });

    testWidgets('and follows a change of card', (tester) async {
      await pump(tester, color: colorOf('cyan'));
      expect(knobColor(tester), colorOf('cyan'));

      await pump(tester, color: colorOf('green'));
      expect(knobColor(tester), colorOf('green'));
    });

    testWidgets('every palette colour is accepted', (tester) async {
      for (final entry in cardPalette) {
        await pump(tester, color: Color(entry.value));
        expect(knobColor(tester), Color(entry.value), reason: entry.key);
      }
    });
  });

  group('the rail still scrubs', () {
    testWidgets('tapping the track picks the card there', (tester) async {
      int? picked;
      await pump(
        tester,
        color: colorOf('cyan'),
        cardCount: 5,
        onFocusChanged: (index) => picked = index,
      );
      final rail = tester.getRect(find.byType(SideRail));
      await tester.tapAt(Offset(rail.center.dx, rail.bottom - 4));
      await tester.pumpAndSettle();
      expect(picked, 4);
    });

    testWidgets('a one-card deck has nowhere to scrub to', (tester) async {
      int? picked;
      await pump(
        tester,
        color: colorOf('cyan'),
        cardCount: 1,
        onFocusChanged: (index) => picked = index,
      );
      final rail = tester.getRect(find.byType(SideRail));
      await tester.tapAt(Offset(rail.center.dx, rail.bottom - 4));
      await tester.pumpAndSettle();
      expect(picked, isNull);
    });
  });

  test('the geometry the rail draws stays consistent', () {
    final knob = solveKnob(trackHeight: 400, cardCount: 6, focusedIndex: 3);
    expect(knob.top, greaterThan(0));
    expect(knob.top + knob.height, lessThanOrEqualTo(400.01));
  });
}
