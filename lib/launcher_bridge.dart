/// Thin wrapper over the `rolidecks/launcher` channel. Marshalling only —
/// every decision about what to show lives in the pure modules beside it.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'models.dart';

class LauncherBridge {
  LauncherBridge._();

  static final LauncherBridge instance = LauncherBridge._();

  static const MethodChannel _channel = MethodChannel('rolidecks/launcher');
  static const EventChannel _packageEvents = EventChannel('rolidecks/packages');

  /// Completed icons, for a synchronous hit that paints in the same frame.
  final Map<String, Uint8List?> _iconCache = {};

  /// Icons still in flight, keyed by package.
  ///
  /// Without this the cache only holds *finished* work, so every rebuild while
  /// an icon is loading starts another platform call for the same package —
  /// and the icon widgets ask for their icon from build(). Scrolling all apps
  /// turned that into a flood of duplicate round-trips across a single-threaded
  /// worker, which is what made the page crawl.
  final Map<String, Future<Uint8List?>> _iconRequests = {};

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

  /// Shortcuts other apps have pinned here. Empty until Rolidecks is the
  /// default launcher — only the host launcher may read them, which is a
  /// legitimate state rather than a failure.
  Future<List<LaunchableApp>> listShortcuts() async {
    final raw =
        await _channel.invokeListMethod<Object?>('listShortcuts') ?? const [];
    return raw
        .whereType<Map<Object?, Object?>>()
        .map(LaunchableApp.shortcutFromPlatform)
        .toList();
  }

  /// Everything launchable, apps and pinned shortcuts together, so cards and
  /// search never have to ask which is which.
  Future<List<LaunchableApp>> listEverything() async {
    final results = await Future.wait([listApps(), listShortcuts()]);
    return [...results[0], ...results[1]];
  }

  /// The icon if it has already been fetched, without touching the channel.
  ///
  /// Lets a widget paint a known icon in the frame it builds, instead of
  /// showing a placeholder for one frame while a Future that is already
  /// complete gets resolved.
  Uint8List? cachedIcon(String key) => _iconCache[key];

  bool hasIcon(String key) => _iconCache.containsKey(key);

  /// The one cache key for [app].
  ///
  /// An app is keyed by package — every launcher entry of a package shares its
  /// icon — and a shortcut by its full id, since it has its own. There is
  /// exactly one key per item on purpose: writing the icon under one key and
  /// reading it under another cached a null against the read key and every app
  /// icon fell back to the placeholder for good.
  static String iconKeyFor(LaunchableApp app) =>
      app.isShortcut ? app.id : app.packageName;

  Uint8List? cachedIconFor(LaunchableApp app) => _iconCache[iconKeyFor(app)];

  bool hasIconFor(LaunchableApp app) =>
      _iconCache.containsKey(iconKeyFor(app));

  /// The icon for [app], whichever kind it is.
  Future<Uint8List?> iconFor(LaunchableApp app, {int size = 144}) {
    if (!app.isShortcut) return appIcon(app.packageName, size: size);

    final key = app.id;
    if (_iconCache.containsKey(key)) {
      return SynchronousFuture(_iconCache[key]);
    }
    final inFlight = _iconRequests[key];
    if (inFlight != null) return inFlight;

    final request = _channel.invokeMethod<Uint8List>(
      'shortcutIcon',
      {'packageName': app.packageName, 'shortcutId': app.shortcutId},
    ).then((bytes) {
      _iconCache[key] = bytes;
      _iconRequests.remove(key);
      return bytes;
    }, onError: (Object error) {
      _iconRequests.remove(key);
      return null;
    });

    _iconRequests[key] = request;
    return request;
  }

  Future<Uint8List?> appIcon(String packageName, {int size = 144}) {
    if (_iconCache.containsKey(packageName)) {
      return SynchronousFuture(_iconCache[packageName]);
    }
    final inFlight = _iconRequests[packageName];
    if (inFlight != null) return inFlight;

    final request = _channel.invokeMethod<Uint8List>(
      'appIcon',
      {'packageName': packageName, 'size': size},
    ).then((bytes) {
      _iconCache[packageName] = bytes;
      _iconRequests.remove(packageName);
      return bytes;
    }, onError: (Object error) {
      _iconRequests.remove(packageName);
      return null;
    });

    _iconRequests[packageName] = request;
    return request;
  }

  void forgetIcon(String packageName) {
    _iconCache.remove(packageName);
    _iconRequests.remove(packageName);
  }

  Future<bool> launch(String packageName) async =>
      await _channel.invokeMethod<bool>('launch', {'packageName': packageName}) ??
      false;

  /// Launches [app], dispatching on its kind — a shortcut goes through
  /// LauncherApps rather than a launch intent.
  Future<bool> open(LaunchableApp app) async {
    if (!app.isShortcut) return launch(app.packageName);
    return await _channel.invokeMethod<bool>('launchShortcut', {
          'packageName': app.packageName,
          'shortcutId': app.shortcutId,
        }) ??
        false;
  }

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
