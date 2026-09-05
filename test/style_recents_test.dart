import 'package:flutter_test/flutter_test.dart';
import 'package:rolidecks/card_style.dart';
import 'package:rolidecks/style_recents.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('appendRecent', () {
    test('puts the newest first', () {
      expect(appendRecent(const ['a'], 'b'), ['b', 'a']);
    });

    test('re-picking something moves it up rather than duplicating it', () {
      expect(appendRecent(const ['a', 'b', 'c'], 'c'), ['c', 'a', 'b']);
      expect(appendRecent(const ['a', 'b', 'c'], 'c'), hasLength(3));
    });

    test('skips anything already on the shelf', () {
      // A preset would otherwise appear twice in the same grid.
      expect(
        appendRecent(const ['a'], 'magenta', alreadyShown: ['magenta']),
        ['a'],
      );
    });

    test('caps the list, dropping the oldest', () {
      var recents = <String>[];
      for (var i = 0; i < 20; i++) {
        recents = appendRecent(recents, 'c$i', limit: 5);
      }
      expect(recents, ['c19', 'c18', 'c17', 'c16', 'c15']);
    });

    test('ignores an empty value', () {
      expect(appendRecent(const ['a'], ''), ['a']);
    });
  });

  group('persistence', () {
    test('a custom colour survives to the next session', () async {
      // The whole point: picking a colour is deliberate work, and redoing it
      // after a restart wastes it. A fresh StyleRecents stands in for one.
      final recents = StyleRecents();
      await recents.addColor('#ff3366',
          presets: [for (final entry in cardPalette) entry.key]);
      expect(await StyleRecents().colors(), ['#ff3366']);
    });

    test('a searched icon survives too', () async {
      final recents = StyleRecents();
      await recents.addIcon('rocket_launch', presets: popularIconKeys);
      expect(await StyleRecents().icons(), ['rocket_launch']);
    });

    test('colours and icons do not share a list', () async {
      final recents = StyleRecents();
      await recents.addColor('#ff3366');
      await recents.addIcon('rocket_launch');
      expect(await recents.colors(), ['#ff3366']);
      expect(await recents.icons(), ['rocket_launch']);
    });

    test('a preset is not remembered, since it is already shown', () async {
      final recents = StyleRecents();
      await recents.addIcon('folder', presets: popularIconKeys);
      expect(await recents.icons(), isEmpty);
    });

    test('re-picking reorders the stored list', () async {
      final recents = StyleRecents();
      await recents.addColor('#111111');
      await recents.addColor('#222222');
      expect(await recents.addColor('#111111'), ['#111111', '#222222']);
    });

    test('nothing stored yet reads as empty, not an error', () async {
      expect(await StyleRecents().colors(), isEmpty);
      expect(await StyleRecents().icons(), isEmpty);
    });

    test('clear empties both', () async {
      final recents = StyleRecents();
      await recents.addColor('#ff3366');
      await recents.addIcon('rocket_launch');
      await recents.clear();
      expect(await recents.colors(), isEmpty);
      expect(await recents.icons(), isEmpty);
    });
  });
}
