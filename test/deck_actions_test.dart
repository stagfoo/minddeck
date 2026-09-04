import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minddeck/deck_actions.dart';

Future<void> pump(
  WidgetTester tester, {
  VoidCallback? onAdd,
  VoidCallback? onSettings,
  VoidCallback? onRefresh,
  bool refreshing = false,
  VoidCallback? onLongPressSettings,
}) async {
  tester.view.physicalSize = const Size(393, 451) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          const Expanded(child: SizedBox()),
          DeckActions(
            onAdd: onAdd ?? () {},
            onSettings: onSettings ?? () {},
            onRefresh: onRefresh ?? () {},
            refreshing: refreshing,
            onLongPressSettings: onLongPressSettings,
          ),
        ],
      ),
    ),
  ));
  // A spinner animates forever, so settling would never return.
  if (refreshing) {
    await tester.pump();
  } else {
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('sits at the bottom left, leaving the top edge to the deck',
      (tester) async {
    // A bar above the stack reads as a gap the cards start below, which undoes
    // the impression that they are a deck resting on the screen.
    await pump(tester);
    final add = tester.getRect(find.byIcon(Icons.add_rounded));
    final screen = tester.getRect(find.byType(Scaffold));

    expect(add.left, lessThan(screen.width / 2));
    expect(add.top, greaterThan(screen.height / 2));
  });

  testWidgets('add, refresh then settings, left to right', (tester) async {
    await pump(tester);
    final add = tester.getRect(find.byIcon(Icons.add_rounded)).left;
    final refresh = tester.getRect(find.byIcon(Icons.refresh_rounded)).left;
    final settings = tester.getRect(find.byIcon(Icons.settings_outlined)).left;
    expect(add, lessThan(refresh));
    expect(refresh, lessThan(settings));
  });

  testWidgets('refresh fires', (tester) async {
    var refreshed = 0;
    await pump(tester, onRefresh: () => refreshed++);
    await tester.tap(find.byIcon(Icons.refresh_rounded));
    expect(refreshed, 1);
  });

  testWidgets('a refresh in flight shows a spinner and cannot be re-tapped',
      (tester) async {
    var refreshed = 0;
    await pump(tester, refreshing: true, onRefresh: () => refreshed++);
    expect(find.byIcon(Icons.refresh_rounded), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(CircularProgressIndicator));
    expect(refreshed, 0);
  });

  testWidgets('both buttons fire', (tester) async {
    var added = 0;
    var settings = 0;
    await pump(tester, onAdd: () => added++, onSettings: () => settings++);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.tap(find.byIcon(Icons.settings_outlined));
    expect(added, 1);
    expect(settings, 1);
  });

  testWidgets('long-pressing settings reports the panel geometry',
      (tester) async {
    var reported = 0;
    await pump(tester, onLongPressSettings: () => reported++);
    await tester.longPress(find.byIcon(Icons.settings_outlined));
    expect(reported, 1);
  });

  testWidgets('a plain tap on settings is not a long press', (tester) async {
    var settings = 0;
    var reported = 0;
    await pump(
      tester,
      onSettings: () => settings++,
      onLongPressSettings: () => reported++,
    );
    await tester.tap(find.byIcon(Icons.settings_outlined));
    expect(settings, 1);
    expect(reported, 0);
  });
}
