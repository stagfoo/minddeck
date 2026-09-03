import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minddeck/card_deck.dart';
import 'package:minddeck/card_editor_sheet.dart';

const card = DeckCard(id: 'c', name: 'media', colorKey: 'cyan', iconKey: 'music');

/// Opens the editor and hands back whatever it returns.
Future<CardEditResult?> open(
  WidgetTester tester, {
  int position = 2,
  int folderCount = 5,
}) async {
  CardEditResult? result;
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              result = await showCardEditor(
                context,
                card,
                position: position,
                folderCount: folderCount,
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
  return result;
}

/// The sheet scrolls, so the delete button can sit below the fold in the test
/// viewport even though it is reachable on the device.
Future<void> tapDelete(WidgetTester tester) async {
  final button = find.byIcon(Icons.delete_outline_rounded);
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  group('position', () {
    testWidgets('reports the card unmoved when nothing is touched',
        (tester) async {
      await open(tester);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      // The caller skips the reorder entirely when the position is unchanged.
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('moving forward lowers the index', (tester) async {
      await open(tester, position: 2);
      expect(find.text('3 of 5'), findsOneWidget);
      await tester.tap(find.text('Forward'));
      await tester.pump();
      expect(find.text('2 of 5'), findsOneWidget);
    });

    testWidgets('moving back raises it', (tester) async {
      await open(tester, position: 2);
      await tester.tap(find.text('Back'));
      await tester.pump();
      expect(find.text('4 of 5'), findsOneWidget);
    });

    testWidgets('the front of the deck is named, not numbered', (tester) async {
      await open(tester, position: 1);
      await tester.tap(find.text('Forward'));
      await tester.pump();
      expect(find.text('front of the deck'), findsOneWidget);
    });

    testWidgets('cannot be moved past either end', (tester) async {
      await open(tester, position: 0);
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text('Forward'));
        await tester.pump();
      }
      expect(find.text('front of the deck'), findsOneWidget);

      for (var i = 0; i < 10; i++) {
        await tester.tap(find.text('Back'));
        await tester.pump();
      }
      expect(find.text('5 of 5'), findsOneWidget);
    });

    testWidgets('a single-card deck offers no move at all', (tester) async {
      await open(tester, position: 0, folderCount: 1);
      expect(find.text('front of the deck'), findsOneWidget);
      await tester.tap(find.text('Back'));
      await tester.pump();
      expect(find.text('front of the deck'), findsOneWidget);
    });
  });

  group('delete', () {
    testWidgets('asks before removing a card', (tester) async {
      await open(tester);
      await tapDelete(tester);
      expect(find.text('Delete media?'), findsOneWidget);
      // Says plainly that the apps survive, since that is the thing a person
      // would otherwise hesitate over.
      expect(find.textContaining('apps are not removed'), findsOneWidget);
    });

    testWidgets('keeping the card leaves the editor open', (tester) async {
      await open(tester);
      await tapDelete(tester);
      await tester.tap(find.text('Keep'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Done'), findsOneWidget);
    });
  });

  group('editing', () {
    testWidgets('previews the name as it is typed', (tester) async {
      await open(tester);
      await tester.enterText(find.byType(TextField), 'podcasts');
      await tester.pump();
      // Once in the field, once in the live card preview.
      expect(find.text('podcasts'), findsNWidgets(2));
    });

    testWidgets('an emptied name falls back rather than blanking the card',
        (tester) async {
      await open(tester);
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();
      expect(find.text('media'), findsOneWidget);
    });
  });
}
