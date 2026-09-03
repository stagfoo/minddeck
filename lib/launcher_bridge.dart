/// Thin wrapper over the `minddeck/launcher` channel. Marshalling only —
/// every decision about what to show lives in the pure modules beside it.
library;

import 'package:flutter/services.dart';

import 'models.dart';

class LauncherBridge {
  LauncherBridge._();

  static final LauncherBridge instance = LauncherBridge._();

  static const MethodChannel _channel = MethodChannel('minddeck/launcher');
  static const EventChannel _packageEvents = EventChannel('minddeck/packages');

  final Map<String, Uint8List?> _iconCache = {};

  /// Fires whenever a package is installed, removed, replaced or changed, so
  /// the deck can redraw. A home screen still showing a tile for an app that
  /// no longer exists is the most obvious way for a launcher to feel broken.
  Stream<String> get packageChanges =>
      _packageEvents.receiveBroadcastStream().map((event) => '$event');

  Future<List<LaunchableApp>> listApps() async {
    final raw = await _channel.invokeListMethod<Object?>('listApps') ?? const [];
    return raw
        .whereType<Map<Object?, Object?>>()
        .map(LaunchableApp.fromPlatform)
        .toList();
  }

  Future<Uint8List?> appIcon(String packageName, {int size = 144}) async {
    if (_iconCache.containsKey(packageName)) return _iconCache[packageName];
    final bytes = await _channel.invokeMethod<Uint8List>(
      'appIcon',
      {'packageName': packageName, 'size': size},
    );
    _iconCache[packageName] = bytes;
    return bytes;
  }

  void forgetIcon(String packageName) => _iconCache.remove(packageName);

  Future<bool> launch(String packageName) async =>
      await _channel.invokeMethod<bool>('launch', {'packageName': packageName}) ??
      false;

  Future<void> openAppInfo(String packageName) =>
      _channel.invokeMethod<void>('openAppInfo', {'packageName': packageName});

  Future<void> requestUninstall(String packageName) => _channel
      .invokeMethod<void>('requestUninstall', {'packageName': packageName});

  Future<void> openSettings() => _channel.invokeMethod<void>('openSettings');

  /// Opens the system picker for the default home app. There is no API to set
  /// it directly, by design — this is the whole of "make me the launcher".
  Future<void> openHomeSettings() =>
      _channel.invokeMethod<void>('openHomeSettings');

  Future<bool> isDefaultLauncher() async =>
      await _channel.invokeMethod<bool>('isDefaultLauncher') ?? false;

  Future<ScreenMetrics> screenMetrics() async {
    final map = await _channel.invokeMapMethod<Object?, Object?>('screenMetrics');
    return ScreenMetrics.fromPlatform(map ?? const {});
  }

  /// Called from Kotlin when HOME is pressed while already on the home screen.
  void onHomePressed(void Function() handler) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'homePressed') handler();
      return null;
    });
  }
}
