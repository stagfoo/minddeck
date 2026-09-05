import 'package:flutter_test/flutter_test.dart';
import 'package:rolidecks/card_style.dart';
import 'package:rolidecks/icon_catalogue.dart';
import 'package:rolidecks/theme.dart';

void main() {
  group('the catalogue', () {
    test('offers the whole rounded Material set, not a hand-typed handful', () {
      expect(materialIcons.length, greaterThan(2000));
    });

    test('every hand-written key is a real icon', () {
      // These lists are typed out, so a typo would show a folder where a
      // camera was meant.
      for (final key in [...starterIconKeys, ...commonIconKeys]) {
        expect(materialIcons.containsKey(key), isTrue, reason: key);
      }
    });

    test('the common list has no duplicates', () {
      expect(commonIconKeys.toSet(), hasLength(commonIconKeys.length));
    });

    test('keys carry no rounded suffix', () {
      expect(materialIcons.containsKey('folder'), isTrue);
      expect(materialIcons.containsKey('folder_rounded'), isFalse);
    });
  });

  group('normaliseIconKey', () {
    test('accepts anything in the catalogue', () {
      expect(normaliseIconKey('rocket_launch'), 'rocket_launch');
    });

    test('translates the keys the first builds wrote', () {
      // A card saved before the catalogue existed must keep its icon.
      expect(normaliseIconKey('game'), 'sports_esports');
      expect(normaliseIconKey('cog'), 'settings');
      expect(normaliseIconKey('tools'), 'build');
      for (final legacy in legacyIconKeys.keys) {
        expect(materialIcons.containsKey(normaliseIconKey(legacy)), isTrue,
            reason: legacy);
      }
    });

    test('falls back for an unknown or absent key', () {
      expect(normaliseIconKey('not_an_icon_at_all'), fallbackIconKey);
      expect(normaliseIconKey(null), fallbackIconKey);
    });

    test('the fallback is itself a real icon', () {
      expect(materialIcons.containsKey(fallbackIconKey), isTrue);
    });
  });

  group('searchIcons', () {
    test('an empty query offers the common ones, not all 2,200', () {
      expect(searchIcons(''), commonIconKeys);
      expect(searchIcons('   '), commonIconKeys);
    });

    test('the picker opens on more than the editor shelf shows', () {
      // Five on the shelf, a few dozen when the picker opens, everything when
      // you type — each step only when the last one was not enough.
      expect(starterIconKeys, hasLength(5));
      expect(commonIconKeys.length, greaterThan(starterIconKeys.length));
      expect(materialIcons.length, greaterThan(commonIconKeys.length));
      expect(commonIconKeys.take(5), starterIconKeys);
    });

    test('matches anywhere in the name', () {
      final matches = searchIcons('camera');
      expect(matches, contains('photo_camera'));
      expect(matches, contains('camera_alt'));
      expect(matches.length, greaterThan(5));
    });

    test('treats a space as an underscore, so "photo camera" works', () {
      expect(searchIcons('photo camera'), contains('photo_camera'));
    });

    test('is case-insensitive', () {
      expect(searchIcons('ROCKET'), contains('rocket_launch'));
    });

    test('returns nothing rather than everything for a miss', () {
      expect(searchIcons('zzzzznotanicon'), isEmpty);
    });
  });

  group('iconOf', () {
    test('resolves a catalogue key, a legacy key and a bad key', () {
      expect(iconOf('rocket_launch'), materialIcons['rocket_launch']);
      expect(iconOf('game'), materialIcons['sports_esports']);
      expect(iconOf('nonsense'), materialIcons[fallbackIconKey]);
    });
  });
}
