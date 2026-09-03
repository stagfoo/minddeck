import 'package:flutter_test/flutter_test.dart';
import 'package:minddeck/app_order.dart';
import 'package:minddeck/models.dart';

LaunchableApp app(String package, {String? label, bool isSystem = false}) =>
    LaunchableApp(
      packageName: package,
      activityName: '$package.Main',
      label: label ?? package.split('.').last,
      isSystem: isSystem,
    );

void main() {
  final installed = [
    app('com.spotify.music', label: 'Spotify'),
    app('com.whatsapp', label: 'WhatsApp'),
    app('com.android.settings', label: 'Settings', isSystem: true),
    app('org.videolan.vlc', label: 'VLC'),
  ];

  String idOf(String package) => '$package/$package.Main';

  group('resolve', () {
    test('returns pinned apps in deck order, not alphabetical order', () {
      final deck = Deck(pinnedIds: [idOf('org.videolan.vlc'), idOf('com.spotify.music')]);
      expect(deck.resolve(installed).map((a) => a.label), ['VLC', 'Spotify']);
    });

    test('skips pinned ids whose app is not installed', () {
      final deck = Deck(pinnedIds: [idOf('com.gone.app'), idOf('com.whatsapp')]);
      expect(deck.resolve(installed).map((a) => a.label), ['WhatsApp']);
    });

    test('keeps an uninstalled id so reinstalling restores its slot', () {
      // Dropping the id would silently send a reinstalled app to the end of
      // the deck, which is exactly the sort of thing you notice and can't
      // explain.
      final deck = Deck(pinnedIds: [idOf('com.gone.app'), idOf('com.whatsapp')]);
      expect(deck.pinnedIds, contains(idOf('com.gone.app')));

      final reinstalled = [...installed, app('com.gone.app', label: 'Gone')];
      expect(deck.resolve(reinstalled).map((a) => a.label), ['Gone', 'WhatsApp']);
    });
  });

  group('rest', () {
    test('is everything unpinned, alphabetically', () {
      final deck = Deck(pinnedIds: [idOf('com.whatsapp')]);
      expect(deck.rest(installed).map((a) => a.label), ['Settings', 'Spotify', 'VLC']);
    });

    test('is the whole list when nothing is pinned', () {
      expect(const Deck().rest(installed), hasLength(4));
    });

    test('sorts case-insensitively', () {
      final apps = [app('com.z', label: 'zebra'), app('com.a', label: 'Apple')];
      expect(const Deck().rest(apps).map((a) => a.label), ['Apple', 'zebra']);
    });
  });

  group('pin and unpin', () {
    test('pinning appends and is idempotent', () {
      final once = const Deck().pin('a');
      expect(once.pin('a').pinnedIds, ['a']);
      expect(once.pin('b').pinnedIds, ['a', 'b']);
    });

    test('unpinning removes without disturbing the rest', () {
      const deck = Deck(pinnedIds: ['a', 'b', 'c']);
      expect(deck.unpin('b').pinnedIds, ['a', 'c']);
    });

    test('unpinning something absent changes nothing', () {
      const deck = Deck(pinnedIds: ['a']);
      expect(deck.unpin('zz').pinnedIds, ['a']);
    });

    test('toggle flips either way', () {
      const deck = Deck(pinnedIds: ['a']);
      expect(deck.toggle('a').pinnedIds, isEmpty);
      expect(deck.toggle('b').pinnedIds, ['a', 'b']);
    });
  });

  group('reorder', () {
    test('moves a tile forward', () {
      const deck = Deck(pinnedIds: ['a', 'b', 'c']);
      expect(deck.reorder(0, 2).pinnedIds, ['b', 'c', 'a']);
    });

    test('moves a tile backward', () {
      const deck = Deck(pinnedIds: ['a', 'b', 'c']);
      expect(deck.reorder(2, 0).pinnedIds, ['c', 'a', 'b']);
    });

    test('a drag past the end clamps instead of throwing', () {
      // Dragging off the edge of the row is a normal gesture, not an error.
      const deck = Deck(pinnedIds: ['a', 'b', 'c']);
      expect(deck.reorder(0, 99).pinnedIds, ['b', 'c', 'a']);
      expect(deck.reorder(-5, 0).pinnedIds, ['a', 'b', 'c']);
    });

    test('reordering an empty deck is a no-op, not a crash', () {
      expect(const Deck().reorder(0, 1).pinnedIds, isEmpty);
    });

    test('never loses or duplicates an entry', () {
      const deck = Deck(pinnedIds: ['a', 'b', 'c', 'd']);
      for (var from = 0; from < 4; from++) {
        for (var to = 0; to < 4; to++) {
          final result = deck.reorder(from, to).pinnedIds;
          expect(result.toSet(), deck.pinnedIds.toSet(), reason: '$from -> $to');
          expect(result, hasLength(4), reason: '$from -> $to');
        }
      }
    });
  });

  group('seedFrom', () {
    test('puts user apps on the deck ahead of system ones', () {
      final deck = Deck.seedFrom(installed, count: 3);
      final labels = deck.resolve(installed).map((a) => a.label);
      expect(labels, isNot(contains('Settings')));
      expect(labels, hasLength(3));
    });

    test('falls back to system apps when there are not enough user apps', () {
      final deck = Deck.seedFrom(installed, count: 4);
      expect(deck.resolve(installed).map((a) => a.label), contains('Settings'));
    });

    test('an empty device seeds an empty deck rather than failing', () {
      expect(Deck.seedFrom(const []).pinnedIds, isEmpty);
    });
  });

  group('persistence', () {
    test('round-trips through JSON', () {
      const deck = Deck(pinnedIds: ['a', 'b']);
      expect(Deck.fromJson(deck.toJson()).pinnedIds, ['a', 'b']);
    });

    test('survives a corrupt or absent stored value', () {
      expect(Deck.fromJson(null).pinnedIds, isEmpty);
      expect(Deck.fromJson('nonsense').pinnedIds, isEmpty);
      expect(Deck.fromJson([1, 'a', null]).pinnedIds, ['a']);
    });
  });

  group('searchApps', () {
    test('matches label and package, case-insensitively', () {
      expect(searchApps(installed, 'spot').map((a) => a.label), ['Spotify']);
      expect(searchApps(installed, 'VIDEOLAN').map((a) => a.label), ['VLC']);
    });

    test('an empty query returns everything untouched', () {
      expect(searchApps(installed, '   '), hasLength(4));
    });
  });
}
