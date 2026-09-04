/// What the launcher knows about one launchable app.
library;

class LaunchableApp {
  const LaunchableApp({
    required this.packageName,
    required this.activityName,
    required this.label,
    this.isSystem = false,
  });

  final String packageName;

  /// The launcher activity behind this entry. A package can expose more than
  /// one, which is why the list is keyed on the pair rather than the package.
  final String activityName;

  final String label;
  final bool isSystem;

  /// Stable identity for ordering and pinning.
  String get id => '$packageName/$activityName';

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'activityName': activityName,
        'label': label,
        'isSystem': isSystem,
      };

  static LaunchableApp fromJson(Map<String, dynamic> json) => LaunchableApp(
        packageName: json['packageName'] as String,
        activityName: (json['activityName'] as String?) ?? '',
        label: (json['label'] as String?) ?? json['packageName'] as String,
        isSystem: json['isSystem'] as bool? ?? false,
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
