import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolidecks/launcher_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('rolidecks/launcher');
  late List<String> requested;
  late List<Completer<Uint8List?>> pending;

  setUp(() {
    requested = [];
    pending = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method != 'appIcon') return null;
      requested.add(call.arguments['packageName'] as String);
      final completer = Completer<Uint8List?>();
      pending.add(completer);
      return completer.future;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    for (final package in ['com.a', 'com.b']) {
      LauncherBridge.instance.forgetIcon(package);
    }
  });

  test('a second ask while the first is in flight does not hit the platform',
      () async {
    // The icon widgets ask for their icon from build(), so a rebuild before the
    // first fetch lands used to start another one. Across a hundred apps on a
    // single-threaded worker, that is what made all apps crawl.
    final first = LauncherBridge.instance.appIcon('com.a');
    final second = LauncherBridge.instance.appIcon('com.a');
    final third = LauncherBridge.instance.appIcon('com.a');

    expect(requested, ['com.a']);

    final bytes = Uint8List.fromList([1, 2, 3]);
    pending.single.complete(bytes);

    expect(await first, bytes);
    expect(await second, bytes);
    expect(await third, bytes);
    expect(requested, ['com.a']);
  });

  test('different packages are still fetched separately', () async {
    LauncherBridge.instance.appIcon('com.a');
    LauncherBridge.instance.appIcon('com.b');
    expect(requested, ['com.a', 'com.b']);
    for (final completer in pending) {
      completer.complete(Uint8List.fromList([0]));
    }
  });

  test('a finished icon is served from cache, never re-fetched', () async {
    final future = LauncherBridge.instance.appIcon('com.a');
    pending.single.complete(Uint8List.fromList([7]));
    await future;

    requested.clear();
    await LauncherBridge.instance.appIcon('com.a');
    await LauncherBridge.instance.appIcon('com.a');
    expect(requested, isEmpty);
  });

  test('a cached icon is readable synchronously, so it paints in-frame',
      () async {
    expect(LauncherBridge.instance.hasIcon('com.a'), isFalse);
    final future = LauncherBridge.instance.appIcon('com.a');
    pending.single.complete(Uint8List.fromList([9]));
    await future;

    expect(LauncherBridge.instance.hasIcon('com.a'), isTrue);
    expect(LauncherBridge.instance.cachedIcon('com.a'), [9]);
  });

  test('a failed fetch does not wedge the package forever', () async {
    // Without clearing the in-flight entry on error, one failure would make
    // that icon permanently unfetchable for the life of the process.
    final future = LauncherBridge.instance.appIcon('com.a');
    pending.single.completeError(PlatformException(code: 'failed'));
    expect(await future, isNull);

    requested.clear();
    LauncherBridge.instance.appIcon('com.a');
    expect(requested, ['com.a']);
    pending.last.complete(Uint8List.fromList([1]));
  });
}
