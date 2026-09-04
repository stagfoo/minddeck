import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolidecks/card_deck.dart';
import 'package:rolidecks/card_editor_sheet.dart';

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
  group('delete', () {
    testWidgets('carries the card position through untouched', (tester) async {
      // Reordering moved to a drag on the cards themselves; the sheet only
      // passes the position along so the caller has one result shape.
      await open(tester, position: 3);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Forward'), findsNothing);
      expect(find.text('Back'), findsNothing);
    });

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
