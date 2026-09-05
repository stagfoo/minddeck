import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolidecks/card_deck.dart';
import 'package:rolidecks/legacy_shortcuts.dart';
import 'package:rolidecks/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

final downloads = LaunchableApp.legacyShortcut(
  uri: 'intent:#Intent;action=android.intent.action.VIEW;'
      'S.path=/storage/Downloads;end',
  label: 'Downloads',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('identity', () {
    test('a legacy shortcut is identified by its intent', () {
      // The system remembers nothing about these, so the intent is all there
      // is to tell one from another.
      expect(downloads.id, startsWith('legacy:intent:'));
      expect(downloads.isShortcut, isTrue);
      expect(downloads.isLegacyShortcut, isTrue);
      expect(downloads.shortcutId, isNull);
    });

    test('it does not collide with a pinned shortcut', () {
      final pinned = LaunchableApp.shortcut(
        packageName: 'files.fileexplorer.filemanager',
        id: 'downloads',
        label: 'Downloads',
      );
      expect(pinned.id, isNot(downloads.id));
      expect(pinned.isLegacyShortcut, isFalse);
    });
  });

  group('storage', () {
    test('survives a save and load, icon and all', () async {
      final store = LegacyShortcutStore();
      await store.add(StoredShortcut(
        app: downloads,
        icon: Uint8List.fromList([1, 2, 3]),
      ));

      final restored = (await LegacyShortcutStore().load()).single;
      expect(restored.app.label, 'Downloads');
      expect(restored.app.intentUri, downloads.intentUri);
      expect(restored.icon, [1, 2, 3]);
    });

    test('one without an icon is still stored', () async {
      final store = LegacyShortcutStore();
      await store.add(StoredShortcut(app: downloads));
      expect((await store.load()).single.icon, isNull);
    });

    test('adding the same shortcut twice replaces rather than duplicates',
        () async {
      final store = LegacyShortcutStore();
      await store.add(StoredShortcut(app: downloads));
      await store.add(StoredShortcut(
        app: LaunchableApp.legacyShortcut(
          uri: downloads.intentUri!,
          label: 'Downloads (renamed)',
        ),
      ));
      final all = await store.load();
      expect(all, hasLength(1));
      expect(all.single.app.label, 'Downloads (renamed)');
    });

    test('two different intents are kept apart', () async {
      final store = LegacyShortcutStore();
      await store.add(StoredShortcut(app: downloads));
      await store.add(StoredShortcut(
        app: LaunchableApp.legacyShortcut(uri: 'intent:#Intent;S.p=/b;end', label: 'B'),
      ));
      expect(await store.load(), hasLength(2));
    });

    test('remove takes one out', () async {
      final store = LegacyShortcutStore();
      await store.add(StoredShortcut(app: downloads));
      await store.remove(downloads.id);
      expect(await store.load(), isEmpty);
    });

    test('unreadable storage is a miss, not a crash', () async {
      SharedPreferences.setMockInitialValues({
        'rolidecks.legacyShortcuts.v1': 'not json',
      });
      expect(await LegacyShortcutStore().load(), isEmpty);
    });

    test('an entry with no intent is dropped rather than half-loaded', () async {
      SharedPreferences.setMockInitialValues({
        'rolidecks.legacyShortcuts.v1':
            '[{"label":"Broken","kind":"shortcut"}]',
      });
      expect(await LegacyShortcutStore().load(), isEmpty);
    });

    test('a corrupt icon does not take the shortcut down with it', () async {
      SharedPreferences.setMockInitialValues({
        'rolidecks.legacyShortcuts.v1':
            '[{"label":"X","kind":"shortcut","intentUri":"intent:#Intent;end",'
            '"icon":"!!not base64!!"}]',
      });
      final restored = await LegacyShortcutStore().load();
      expect(restored, hasLength(1));
      expect(restored.single.icon, isNull);
    });
  });

  group('cards treat it like anything else', () {
    test('it can be filed and resolved', () {
      var deck = CardDeck.seed();
      final id = deck.folders.first.id;
      deck = deck.assign(downloads.id, id);
      expect(
        deck.cards[deck.indexOfId(id)].resolve([downloads]).single.label,
        'Downloads',
      );
    });
  });
}
