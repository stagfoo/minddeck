import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'launcher_bridge.dart';
import 'models.dart';
import 'theme.dart';

/// The apps on a card: a row you scroll sideways, right on the card itself.
///
/// Sideways rather than a wrapped grid because a card is wide and short — a
/// grid would either shrink the icons or force the card taller than the stack
/// can afford. Scrolling horizontally also keeps the vertical gesture free for
/// the stack, which is the one that has to stay reliable.
class CardAppRow extends StatelessWidget {
  const CardAppRow({
    super.key,
    required this.apps,
    required this.cardColor,
    required this.onTap,
    this.onLongPress,
  });

  final List<LaunchableApp> apps;
  final Color cardColor;
  final ValueChanged<LaunchableApp> onTap;
  final ValueChanged<LaunchableApp>? onLongPress;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 2),
      // The card clips, so a bouncing overscroll would reveal nothing and just
      // look loose. Clamp it.
      physics: const ClampingScrollPhysics(),
      itemCount: apps.length,
      separatorBuilder: (context, index) => const SizedBox(width: 10),
      itemBuilder: (context, index) {
        final app = apps[index];
        return _CardApp(
          app: app,
          onTap: () => onTap(app),
          onLongPress: onLongPress == null ? null : () => onLongPress!(app),
        );
      },
    );
  }
}

class _CardApp extends StatelessWidget {
  const _CardApp({required this.app, required this.onTap, this.onLongPress});

  final LaunchableApp app;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: SizedBox(
        width: 58,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                // A soft dark well behind the icon, so app artwork of any
                // colour still separates from a bright card.
                color: DeckColors.onCard.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              padding: const EdgeInsets.all(6),
              child: _Icon(packageName: app.packageName),
            ),
            const SizedBox(height: 4),
            Text(
              app.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: deckText(
                size: 9.5,
                weight: 600,
                height: 1.1,
                color: DeckColors.onCard.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Icon extends StatelessWidget {
  const _Icon({required this.packageName});

  final String packageName;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: LauncherBridge.instance.appIcon(packageName),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) {
          return Icon(Icons.android,
              size: 20, color: DeckColors.onCard.withValues(alpha: 0.5));
        }
        return Image.memory(bytes, fit: BoxFit.contain, gaplessPlayback: true);
      },
    );
  }
}
