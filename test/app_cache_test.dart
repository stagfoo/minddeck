import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rolidecks/app_cache.dart';
import 'package:rolidecks/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

LaunchableApp app(String package, {String? label, bool isSystem = false}) =>
    LaunchableApp(
      packageName: package,
      activityName: '$package.Main',
      label: label ?? package.split('.').last,
      isSystem: isSystem,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('round trip', () {
    test('survives a save and load intact', () async {
      final apps = [
        app('com.spotify.music', label: 'Spotify'),
        app('com.android.settings', label: 'Settings', isSystem: true),
      ];
      final cache = AppCache();
      await cache.save(apps);

      final restored = await cache.load();
      expect(restored, isNotNull);
      expect(restored!.apps.map((a) => a.id), apps.map((a) => a.id));
      expect(restored.apps[0].label, 'Spotify');
      expect(restored.apps[1].isSystem, isTrue);
    });

    test('keeps the activity, not just the package', () async {
      // The id is package/activity, and a package can expose more than one
      // launcher entry — dropping the activity would merge them.
      final cache = AppCache();
      await cache.save([app('com.a')]);
      final restored = await cache.load();
      expect(restored!.apps.single.activityName, 'com.a.Main');
      expect(restored.apps.single.id, 'com.a/com.a.Main');
    });

    test('records when it was captured', () async {
      final cache = AppCache();
      await cache.save([app('com.a')]);
      final restored = await cache.load();
      expect(
        DateTime.now().difference(restored!.capturedAt).inSeconds,
        lessThan(5),
      );
    });
  });

  group('a bad cache is a miss, not a crash', () {
    test('nothing stored', () async {
      expect(await AppCache().load(), isNull);
    });

    test('not JSON at all', () async {
      SharedPreferences.setMockInitialValues({'rolidecks.apps.v1': 'nonsense'});
      expect(await AppCache().load(), isNull);
    });

    test('JSON of the wrong shape', () async {
      SharedPreferences.setMockInitialValues({'rolidecks.apps.v1': '[1,2,3]'});
      expect(await AppCache().load(), isNull);
    });

    test('a snapshot from a newer schema', () async {
      // Written by a future build that may mean something different by these
      // fields; refetching from the platform is always safe.
      SharedPreferences.setMockInitialValues({
        'rolidecks.apps.v1': jsonEncode({
          'schemaVersion': AppCache.schemaVersion + 1,
          'apps': [app('com.a').toJson()],
        }),
      });
      expect(await AppCache().load(), isNull);
    });

    test('an entry missing its package name', () async {
      SharedPreferences.setMockInitialValues({
        'rolidecks.apps.v1': jsonEncode({
          'schemaVersion': AppCache.schemaVersion,
          'apps': [
            {'label': 'No package here'},
          ],
        }),
      });
      expect(await AppCache().load(), isNull);
    });

    test('clear removes it', () async {
      final cache = AppCache();
      await cache.save([app('com.a')]);
      await cache.clear();
      expect(await cache.load(), isNull);
    });
  });

  group('appListsDiffer', () {
    test('is false for the same list', () {
      final apps = [app('com.a'), app('com.b')];
      expect(appListsDiffer(apps, apps), isFalse);
      expect(appListsDiffer(apps, [app('com.a'), app('com.b')]), isFalse);
    });

    test('spots an install, an uninstall and a reorder', () {
      expect(appListsDiffer([app('com.a')], [app('com.a'), app('com.b')]), isTrue);
      expect(appListsDiffer([app('com.a'), app('com.b')], [app('com.a')]), isTrue);
      expect(
        appListsDiffer([app('com.a'), app('com.b')], [app('com.b'), app('com.a')]),
        isTrue,
      );
    });

    test('spots a rename even though the packages are unchanged', () {
      // An app relabelled, or a locale change, has to redraw.
      expect(
        appListsDiffer(
          [app('com.a', label: 'Before')],
          [app('com.a', label: 'After')],
        ),
        isTrue,
      );
    });

    test('two empty lists do not differ', () {
      expect(appListsDiffer(const [], const []), isFalse);
    });
  });
}
