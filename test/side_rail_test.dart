import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolidecks/card_style.dart';
import 'package:rolidecks/side_rail.dart';
import 'package:rolidecks/stack_layout.dart';
import 'package:rolidecks/theme.dart';

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
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Sounds and haptics both go out over the platform channel, so counting the
  /// calls is the only way to assert them without a device.
  late List<String> sounds;
  late List<String> haptics;

  setUp(() {
    sounds = [];
    haptics = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemSound.play') {
        sounds.add('${call.arguments}');
      }
      if (call.method == 'HapticFeedback.vibrate') {
        haptics.add('${call.arguments}');
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('the knob ticks', () {
    testWidgets('once when a tap lands on a different card', (tester) async {
      await pump(tester, color: colorOf('cyan'), cardCount: 5);
      final rail = tester.getRect(find.byType(SideRail));
      await tester.tapAt(Offset(rail.center.dx, rail.bottom - 4));
      await tester.pumpAndSettle();

      expect(sounds, ['SystemSoundType.click']);
      expect(haptics, ['HapticFeedbackType.selectionClick']);
    });

    testWidgets('not at all when the card does not change', (tester) async {
      // Scrubbing within one card's band must stay quiet, or the rail rattles
      // continuously under a slow thumb.
      await pump(tester, color: colorOf('cyan'), cardCount: 5, focusedIndex: 0);
      final rail = tester.getRect(find.byType(SideRail));
      await tester.tapAt(Offset(rail.center.dx, rail.top + 2));
      await tester.pumpAndSettle();

      expect(sounds, isEmpty);
      expect(haptics, isEmpty);
    });

    testWidgets('once per card a drag passes, not once per frame',
        (tester) async {
      await pump(tester, color: colorOf('cyan'), cardCount: 5, focusedIndex: 0);
      final rail = tester.getRect(find.byType(SideRail));

      final gesture = await tester.startGesture(
        Offset(rail.center.dx, rail.top + 2),
      );
      // Many small moves down the whole track: the count must follow the cards
      // crossed, not the number of updates.
      for (var i = 0; i < 40; i++) {
        await gesture.moveBy(Offset(0, rail.height / 40));
        await tester.pump();
      }
      await gesture.up();
      await tester.pumpAndSettle();

      // Four boundaries in a five-card deck, and forty drag updates crossing
      // them: the count follows the cards, not the frames.
      expect(sounds, hasLength(4));
      expect(sounds.every((s) => s == 'SystemSoundType.click'), isTrue);
      expect(haptics, hasLength(4));
    });

    testWidgets('crossing back over a boundary ticks again', (tester) async {
      await pump(tester, color: colorOf('cyan'), cardCount: 5, focusedIndex: 0);
      final rail = tester.getRect(find.byType(SideRail));

      final gesture = await tester.startGesture(
        Offset(rail.center.dx, rail.top + 2),
      );
      await gesture.moveTo(Offset(rail.center.dx, rail.bottom - 2));
      await tester.pump();
      await gesture.moveTo(Offset(rail.center.dx, rail.top + 2));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      // Down then back up: the rail must not think it is still on the card it
      // ticked for on the way out.
      expect(sounds.length, greaterThanOrEqualTo(2));
    });

    testWidgets('a single-card deck never ticks', (tester) async {
      await pump(tester, color: colorOf('cyan'), cardCount: 1);
      final rail = tester.getRect(find.byType(SideRail));
      await tester.tapAt(Offset(rail.center.dx, rail.bottom - 4));
      await tester.pumpAndSettle();
      expect(sounds, isEmpty);
    });
  });

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
