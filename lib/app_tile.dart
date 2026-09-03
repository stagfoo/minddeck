import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'launcher_bridge.dart';
import 'models.dart';
import 'theme.dart';

/// One rounded-square card on the deck.
///
/// The Switch signals selection by lifting the card and drawing a bright rim
/// around it rather than by changing its fill, which keeps the artwork
/// readable. Same here: scale plus rim, never a tint over the icon.
class AppTile extends StatefulWidget {
  const AppTile({
    super.key,
    required this.app,
    required this.size,
    required this.onTap,
    this.onLongPress,
    this.selected = false,
    this.showLabel = true,
  });

  final LaunchableApp app;
  final double size;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool selected;
  final bool showLabel;

  @override
  State<AppTile> createState() => _AppTileState();
}

class _AppTileState extends State<AppTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final lifted = widget.selected || _pressed;
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: lifted ? 1.06 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: DeckColors.card,
                borderRadius: BorderRadius.circular(DeckMetrics.tileRadius),
                border: Border.all(
                  color: lifted ? DeckColors.selection : DeckColors.cardEdge,
                  width: lifted ? 3 : 1,
                ),
                boxShadow: lifted
                    ? [
                        BoxShadow(
                          color: DeckColors.selection.withValues(alpha: 0.35),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: EdgeInsets.all(widget.size * 0.14),
                child: _Icon(packageName: widget.app.packageName),
              ),
            ),
            if (widget.showLabel) ...[
              const SizedBox(height: 6),
              SizedBox(
                width: widget.size + 8,
                child: Text(
                  widget.app.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: lifted ? DeckColors.text : DeckColors.textDim,
                  ),
                ),
              ),
            ],
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
      // The bridge memoises per package, so scrolling the all-apps list does
      // not re-cross the channel for icons already fetched.
      future: LauncherBridge.instance.appIcon(packageName),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) {
          return const Icon(Icons.android, color: DeckColors.textDim);
        }
        return Image.memory(bytes, fit: BoxFit.contain, gaplessPlayback: true);
      },
    );
  }
}
