import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'launcher_bridge.dart';
import 'models.dart';
import 'theme.dart';

/// One app's launcher icon.
///
/// Paints straight from the cache when the icon is already known, so a
/// re-scroll over apps that have been seen costs a lookup rather than a frame
/// of placeholder and a Future round-trip. Only a genuinely new icon goes
/// through a FutureBuilder.
class AppIconImage extends StatelessWidget {
  const AppIconImage({
    super.key,
    required this.app,
    required this.size,
    this.color,
  });

  /// The item, not a package name: a pinned shortcut has its own icon, drawn
  /// by the app that pinned it, and keyed separately from its host app's.
  final LaunchableApp app;

  /// Logical size the icon is drawn at. Used to decode at the size actually
  /// needed rather than at the source resolution — a hundred icons decoded
  /// three times larger than they are shown is memory and time for nothing.
  final double size;

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cached = LauncherBridge.instance.cachedIconFor(app);
    if (LauncherBridge.instance.hasIconFor(app)) {
      return _paint(context, cached);
    }
    return FutureBuilder<Uint8List?>(
      future: LauncherBridge.instance.iconFor(app),
      builder: (context, snapshot) => _paint(context, snapshot.data),
    );
  }

  Widget _paint(BuildContext context, Uint8List? bytes) {
    if (bytes == null) {
      return Icon(
        Icons.android,
        size: size * 0.55,
        color: color ?? DeckColors.textDim,
      );
    }
    final pixels = (size * MediaQuery.devicePixelRatioOf(context)).round();
    return Image.memory(
      bytes,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      cacheWidth: pixels,
      cacheHeight: pixels,
    );
  }
}
