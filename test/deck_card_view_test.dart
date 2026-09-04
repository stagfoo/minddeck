import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolidecks/card_deck.dart';
import 'package:rolidecks/deck_card_view.dart';
import 'package:rolidecks/models.dart';
import 'package:rolidecks/stack_layout.dart';

LaunchableApp app(String package, {String? label}) => LaunchableApp(
      packageName: package,
      activityName: '$package.Main',
      label: label ?? package.split('.').last,
    );

Widget host(Widget child, {double width = 379}) => MaterialApp(
      home: Scaffold(
        body: SizedBox(width: width, child: child),
      ),
    );

void main() {
  const card = DeckCard(
    id: 'c',
    name: 'media',
    colorKey: 'cyan',
    iconKey: 'music',
  );

  // The first build laid covered cards out at strip height and squeezed their
  // header into it, which overflowed by two pixels on the device — a red-and-
  // yellow bar across every card in the stack. These pin that shut.
  group('does not overflow', () {
    testWidgets('at the shortest strip the layout will ever produce',
        (tester) async {
      await tester.pumpWidget(host(
        DeckCardView(
          card: card,
          height: StackStyle.headerHeight,
          focused: false,
          apps: const [],
          totalInstalled: 40,
          onTap: () {},
          onAppTap: (_) {},
        ),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('with a long name and a full app row', (tester) async {
      await tester.pumpWidget(host(
        DeckCardView(
          card: card.copyWith(name: 'an extremely long card name that wraps'),
          height: StackStyle.standard.minCardHeight,
          focused: true,
          apps: [for (var i = 0; i < 12; i++) app('com.app$i')],
          totalInstalled: 40,
          onTap: () {},
          onAppTap: (_) {},
        ),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('on a narrow screen', (tester) async {
      await tester.pumpWidget(host(
        DeckCardView(
          card: card,
          height: StackStyle.standard.minCardHeight,
          focused: true,
          apps: [for (var i = 0; i < 6; i++) app('com.app$i')],
          totalInstalled: 40,
          onTap: () {},
          onAppTap: (_) {},
        ),
        width: 240,
      ));
      expect(tester.takeException(), isNull);
    });
  });

  group('the header survives being covered', () {
    testWidgets('the name is still rendered at strip height', (tester) async {
      // The strip is all you see of a covered card, so the name has to be in it.
      await tester.pumpWidget(host(
        DeckCardView(
          card: card,
          height: StackStyle.headerHeight,
          focused: false,
          apps: const [],
          totalInstalled: 40,
          onTap: () {},
          onAppTap: (_) {},
        ),
      ));
      expect(find.text('media'), findsOneWidget);
    });
  });

  group('corners', () {
    BorderRadius radiusOf(WidgetTester tester) {
      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).first,
      );
      return ((container.decoration! as BoxDecoration).borderRadius!
          as BorderRadius);
    }

    testWidgets('a flush card squares only its top corners', (tester) async {
      // Its top edge lands exactly on the bottom edge of the card in front, so
      // rounding there would show the background through as two dark notches.
      await tester.pumpWidget(host(
        DeckCardView(
          card: card,
          height: 158,
          focused: true,
          flushTop: true,
          apps: const [],
          totalInstalled: 40,
          onTap: () {},
          onAppTap: (_) {},
        ),
      ));
      final radius = radiusOf(tester);
      expect(radius.topLeft, Radius.zero);
      expect(radius.topRight, Radius.zero);
      expect(radius.bottomLeft.x, greaterThan(0));
      expect(radius.bottomRight.x, greaterThan(0));
    });

    testWidgets('a bleed grows the box upward without moving the contents',
        (tester) async {
      // The bleed hides behind the card in front, filling the slivers its
      // rounded bottom corners would otherwise leave. It must not shift what
      // the card shows.
      Rect stripOf(WidgetTester tester) => tester.getRect(find.text('media'));

      await tester.pumpWidget(host(
        DeckCardView(
          card: card,
          height: 158,
          focused: true,
          apps: const [],
          totalInstalled: 40,
          onTap: () {},
          onAppTap: (_) {},
        ),
      ));
      final withoutBleed = stripOf(tester);
      final plainHeight = tester.getSize(find.byType(AnimatedContainer).first);

      await tester.pumpWidget(host(
        DeckCardView(
          card: card,
          height: 158,
          focused: true,
          flushTop: true,
          topBleed: 14,
          apps: const [],
          totalInstalled: 40,
          onTap: () {},
          onAppTap: (_) {},
        ),
      ));
      // The card animates its height, so measure once it has settled rather
      // than at the first frame of the transition.
      await tester.pumpAndSettle();
      final bledHeight = tester.getSize(find.byType(AnimatedContainer).first);

      expect(bledHeight.height, plainHeight.height + 14);
      // The name strip is measured from the card's bottom, so it stays put.
      expect(stripOf(tester).bottom, closeTo(withoutBleed.bottom + 14, 0.01));
    });

    testWidgets('an ordinary card keeps all four rounded', (tester) async {
      await tester.pumpWidget(host(
        DeckCardView(
          card: card,
          height: 158,
          focused: true,
          apps: const [],
          totalInstalled: 40,
          onTap: () {},
          onAppTap: (_) {},
        ),
      ));
      final radius = radiusOf(tester);
      expect(radius.topLeft.x, greaterThan(0));
      expect(radius.bottomLeft.x, greaterThan(0));
    });
  });

  group('apps on the card', () {
    testWidgets('are shown and are tappable', (tester) async {
      LaunchableApp? tapped;
      await tester.pumpWidget(host(
        DeckCardView(
          card: card,
          height: 158,
          focused: true,
          apps: [app('com.a', label: 'Alpha'), app('com.b', label: 'Bravo')],
          totalInstalled: 40,
          onTap: () {},
          onAppTap: (value) => tapped = value,
        ),
      ));
      expect(find.text('Alpha'), findsOneWidget);
      await tester.tap(find.text('Alpha'));
      expect(tapped?.packageName, 'com.a');
    });

    testWidgets('scroll sideways rather than overflowing the card',
        (tester) async {
      await tester.pumpWidget(host(
        DeckCardView(
          card: card,
          height: 158,
          focused: true,
          apps: [for (var i = 0; i < 20; i++) app('com.app$i')],
          totalInstalled: 40,
          onTap: () {},
          onAppTap: (_) {},
        ),
      ));
      expect(tester.takeException(), isNull);
      final row = find.byType(ListView);
      expect(row, findsOneWidget);
      expect(tester.widget<ListView>(row).scrollDirection, Axis.horizontal);
    });

    testWidgets('an empty card says so instead of showing a blank row',
        (tester) async {
      await tester.pumpWidget(host(
        DeckCardView(
          card: card,
          height: 158,
          focused: true,
          apps: const [],
          totalInstalled: 40,
          onTap: () {},
          onAppTap: (_) {},
        ),
      ));
      expect(find.textContaining('empty'), findsOneWidget);
    });

    testWidgets('the all-apps card counts everything installed', (tester) async {
      await tester.pumpWidget(host(
        DeckCardView(
          card: CardDeck.allAppsCard,
          height: 158,
          focused: true,
          apps: [app('com.a')],
          totalInstalled: 42,
          onTap: () {},
          onAppTap: (_) {},
        ),
      ));
      expect(find.text('42'), findsOneWidget);
    });
  });
}
