import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolidecks/app_menu_sheet.dart';
import 'package:rolidecks/card_deck.dart';
import 'package:rolidecks/models.dart';

const app = LaunchableApp(
  packageName: 'files.fileexplorer.filemanager',
  activityName: 'files.fileexplorer.filemanager.Main',
  label: 'File Manager - XFolder',
);

CardDeck deckOf(int folders) => CardDeck.normalised([
      for (var i = 0; i < folders; i++)
        DeckCard(
          id: 'card-$i',
          name: 'card $i',
          colorKey: 'cyan',
          iconKey: 'folder',
        ),
    ]);

/// Opens the sheet on a phone-sized surface and returns the choice.
Future<AppMenuChoice?> open(
  WidgetTester tester, {
  required CardDeck deck,
  DeckCard? from,
  Size size = const Size(393, 451),
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  AppMenuChoice? choice;
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              choice = await showAppMenuSheet(
                context,
                app: app,
                deck: deck,
                from: from ?? deck.cards.last,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return choice;
}

void main() {
  group('does not overflow', () {
    // On the device this sheet was a plain Column: with six cards it ran 313
    // pixels off the bottom of the screen, and the cards below the fold could
    // not be reached at all.
    testWidgets('with a deck big enough to run past the screen',
        (tester) async {
      await open(tester, deck: deckOf(6));
      expect(tester.takeException(), isNull);
    });

    testWidgets('with an absurd number of cards', (tester) async {
      await open(tester, deck: deckOf(30));
      expect(tester.takeException(), isNull);
    });

    testWidgets('on a very short screen', (tester) async {
      await open(tester, deck: deckOf(8), size: const Size(360, 320));
      expect(tester.takeException(), isNull);
    });
  });

  group('every card is reachable', () {
    testWidgets('the last card can be scrolled to and chosen', (tester) async {
      final deck = deckOf(8);
      await open(tester, deck: deck);

      final last = find.text('File under card 7');
      await tester.scrollUntilVisible(last, 80,
          scrollable: find.byType(Scrollable).last);
      await tester.pumpAndSettle();
      await tester.tap(last);
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('app info survives at the bottom of a long list',
        (tester) async {
      await open(tester, deck: deckOf(10));
      final info = find.text('App info');
      await tester.scrollUntilVisible(info, 80,
          scrollable: find.byType(Scrollable).last);
      expect(info, findsOneWidget);
    });
  });

  group('choices', () {
    testWidgets('filing under a card reports that card', (tester) async {
      final deck = deckOf(3);
      AppMenuChoice? choice;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  choice = await showAppMenuSheet(context,
                      app: app, deck: deck, from: deck.cards.last);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('File under card 1'));
      await tester.pumpAndSettle();
      expect(choice, isA<FileUnder>());
      expect((choice! as FileUnder).cardId, 'card-1');
    });

    testWidgets('an unfiled app is not offered "remove"', (tester) async {
      // Nothing to remove it from, so the row would do nothing.
      await open(tester, deck: deckOf(3));
      expect(find.textContaining('Remove from'), findsNothing);
      expect(find.text('Unfile'), findsNothing);
    });

    testWidgets('a filed app is offered "remove"', (tester) async {
      final deck = deckOf(3).assign(app.id, 'card-1');
      await open(tester, deck: deck);
      expect(find.text('Unfile'), findsOneWidget);
    });

    testWidgets('the card an app is already filed under is ticked',
        (tester) async {
      final deck = deckOf(3).assign(app.id, 'card-2');
      await open(tester, deck: deck);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });
}
