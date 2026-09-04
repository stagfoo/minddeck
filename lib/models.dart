/// What the launcher knows about one thing it can launch.
library;

/// An entry is either an installed app or a shortcut another app has pinned
/// here — a folder from a file manager, a conversation from a chat app. They
/// sit in the same list so cards, search and filing do not have to know the
/// difference; only launching and drawing an icon do.
enum LaunchKind { app, shortcut }

class LaunchableApp {
  const LaunchableApp({
    required this.packageName,
    required this.activityName,
    required this.label,
    this.isSystem = false,
    this.kind = LaunchKind.app,
    this.shortcutId,
  });

  /// A shortcut pinned by another app.
  const LaunchableApp.shortcut({
    required this.packageName,
    required String id,
    required this.label,
  })  : shortcutId = id,
        kind = LaunchKind.shortcut,
        activityName = '',
        isSystem = false;

  final String packageName;

  /// The launcher activity behind this entry. A package can expose more than
  /// one, which is why the list is keyed on the pair rather than the package.
  final String activityName;

  final String label;
  final bool isSystem;

  final LaunchKind kind;

  /// Set only for [LaunchKind.shortcut].
  final String? shortcutId;

  bool get isShortcut => kind == LaunchKind.shortcut;

  /// Stable identity for ordering and filing.
  ///
  /// Shortcuts are prefixed so they can never collide with an app whose
  /// activity happens to share the name, and so an id read back from an old
  /// deck still says which kind it was.
  String get id => isShortcut
      ? 'shortcut:$packageName/$shortcutId'
      : '$packageName/$activityName';

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'activityName': activityName,
        'label': label,
        'isSystem': isSystem,
        if (isShortcut) 'kind': 'shortcut',
        if (shortcutId != null) 'shortcutId': shortcutId,
      };

  static LaunchableApp fromJson(Map<String, dynamic> json) {
    final shortcutId = json['shortcutId'] as String?;
    final isShortcut = json['kind'] == 'shortcut' && shortcutId != null;
    return LaunchableApp(
      packageName: json['packageName'] as String,
      activityName: (json['activityName'] as String?) ?? '',
      label: (json['label'] as String?) ?? json['packageName'] as String,
      isSystem: json['isSystem'] as bool? ?? false,
      kind: isShortcut ? LaunchKind.shortcut : LaunchKind.app,
      shortcutId: shortcutId,
    );
  }

  static LaunchableApp shortcutFromPlatform(Map<Object?, Object?> map) =>
      LaunchableApp.shortcut(
        packageName: map['packageName'] as String,
        id: map['shortcutId'] as String,
        label: (map['label'] as String?) ?? map['shortcutId'] as String,
      );

  static LaunchableApp fromPlatform(Map<Object?, Object?> map) => LaunchableApp(
        packageName: map['packageName'] as String,
        activityName: (map['activityName'] as String?) ?? '',
        label: (map['label'] as String?) ?? map['packageName'] as String,
        isSystem: map['isSystem'] as bool? ?? false,
      );
}

/// The panel, as measured rather than assumed.
class ScreenMetrics {
  const ScreenMetrics({
    required this.widthPx,
    required this.heightPx,
    required this.density,
    required this.densityDpi,
  });

  final int widthPx;
  final int heightPx;
  final double density;
  final int densityDpi;

  double get widthDp => widthPx / density;

  double get heightDp => heightPx / density;

  /// The Mind One's panel is 1240 × 1080 in landscape — about 1.15:1, far
  /// closer to square than the 16:9 a Switch-style layout normally assumes.
  double get aspectRatio => widthPx / heightPx;

  static ScreenMetrics fromPlatform(Map<Object?, Object?> map) => ScreenMetrics(
        widthPx: (map['widthPx'] as num?)?.toInt() ?? 0,
        heightPx: (map['heightPx'] as num?)?.toInt() ?? 0,
        density: (map['density'] as num?)?.toDouble() ?? 1,
        densityDpi: (map['densityDpi'] as num?)?.toInt() ?? 0,
      );

  @override
  String toString() =>
      '${widthPx}x$heightPx @${density}x (${widthDp.round()}x${heightDp.round()} dp)';
}
