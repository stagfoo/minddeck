import 'package:flutter_test/flutter_test.dart';
import 'package:rolidecks/app_cache.dart';
import 'package:rolidecks/card_deck.dart';
import 'package:rolidecks/models.dart';

final folderShortcut = LaunchableApp.shortcut(
  packageName: 'files.fileexplorer.filemanager',
  id: 'folder-downloads',
  label: 'Downloads',
);

const anApp = LaunchableApp(
  packageName: 'com.spotify.music',
  activityName: 'com.spotify.music.Main',
  label: 'Spotify',
);

void main() {
  group('identity', () {
    test('a shortcut id is prefixed, so it cannot collide with an app', () {
      // An app whose activity happened to match a shortcut id would otherwise
      // share an entry, and filing one would file the other.
      expect(folderShortcut.id,
          'shortcut:files.fileexplorer.filemanager/folder-downloads');
      expect(folderShortcut.id, isNot(anApp.id));
      expect(folderShortcut.isShortcut, isTrue);
      expect(anApp.isShortcut, isFalse);
    });

    test('two shortcuts from one app stay distinct', () {
      final other = LaunchableApp.shortcut(
        packageName: folderShortcut.packageName,
        id: 'folder-pictures',
        label: 'Pictures',
      );
      expect(other.id, isNot(folderShortcut.id));
    });
  });

  group('storage', () {
    test('a shortcut survives the app cache', () {
      final restored =
          LaunchableApp.fromJson(folderShortcut.toJson());
      expect(restored.isShortcut, isTrue);
      expect(restored.shortcutId, 'folder-downloads');
      expect(restored.label, 'Downloads');
      expect(restored.id, folderShortcut.id);
    });

    test('an app does not come back as a shortcut', () {
      final restored = LaunchableApp.fromJson(anApp.toJson());
      expect(restored.isShortcut, isFalse);
      expect(restored.shortcutId, isNull);
      expect(restored.id, anApp.id);
    });

    test('a snapshot from before shortcuts existed still reads as an app', () {
      final restored = LaunchableApp.fromJson({
        'packageName': 'com.a',
        'activityName': 'com.a.Main',
        'label': 'A',
      });
      expect(restored.isShortcut, isFalse);
    });

    test('a "shortcut" entry with no id is not trusted as one', () {
      final restored = LaunchableApp.fromJson({
        'packageName': 'com.a',
        'activityName': '',
        'label': 'A',
        'kind': 'shortcut',
      });
      expect(restored.isShortcut, isFalse);
    });
  });

  group('cards treat a shortcut like anything else', () {
    test('it can be filed, found and unfiled', () {
      var deck = CardDeck.seed();
      final id = deck.folders.first.id;

      deck = deck.assign(folderShortcut.id, id);
      expect(deck.cardIdFor(folderShortcut.id), id);

      final card = deck.cards[deck.indexOfId(id)];
      expect(card.resolve([anApp, folderShortcut]).single.label, 'Downloads');

      deck = deck.unassign(folderShortcut.id);
      expect(deck.cardIdFor(folderShortcut.id), isNull);
    });

    test('it shows up in all apps alongside real apps', () {
      final all = CardDeck.allAppsCard.resolve([anApp, folderShortcut]);
      expect(all.map((a) => a.label), ['Downloads', 'Spotify']);
    });

    test('search matches its label', () {
      expect(
        searchApps([anApp, folderShortcut], 'down').single.label,
        'Downloads',
      );
    });

    test('an unpinned shortcut drops off the card without losing its slot', () {
      // Same rule as an uninstalled app: the id stays filed, so re-pinning it
      // puts it back where it was.
      var deck = CardDeck.seed();
      final id = deck.folders.first.id;
      deck = deck.assign(folderShortcut.id, id);
      final card = deck.cards[deck.indexOfId(id)];
      expect(card.resolve([anApp]), isEmpty);
      expect(card.appIds, contains(folderShortcut.id));
    });
  });

  group('the list notices shortcut changes', () {
    test('pinning one counts as a difference worth redrawing', () {
      expect(appListsDiffer([anApp], [anApp, folderShortcut]), isTrue);
    });

    test('renaming one does too', () {
      final renamed = LaunchableApp.shortcut(
        packageName: folderShortcut.packageName,
        id: 'folder-downloads',
        label: 'Downloads (SD)',
      );
      expect(appListsDiffer([folderShortcut], [renamed]), isTrue);
    });
  });
}
