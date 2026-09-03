import 'package:flutter/material.dart';

import 'theme.dart';

/// The thin bar above the deck: just the two actions.
///
/// No clock — Android already draws one in the status bar a few pixels above,
/// and two of them stacked was the first thing that looked wrong on the device.
class StatusStrip extends StatelessWidget {
  const StatusStrip({
    super.key,
    required this.onSettings,
    required this.onAdd,
    this.onLongPressSettings,
  });

  final VoidCallback onSettings;
  final VoidCallback onAdd;

  /// Long-pressing settings reports the measured panel geometry. There is no
  /// adb on this device day to day, and the layout is tuned to numbers that had
  /// to be guessed until it ran — this is how they get confirmed.
  final VoidCallback? onLongPressSettings;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DeckMetrics.stripHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _StripButton(icon: Icons.add_rounded, onTap: onAdd),
            const SizedBox(width: 4),
            _StripButton(
              icon: Icons.settings_outlined,
              onTap: onSettings,
              onLongPress: onLongPressSettings,
            ),
          ],
        ),
      ),
    );
  }
}

class _StripButton extends StatelessWidget {
  const _StripButton({required this.icon, required this.onTap, this.onLongPress});

  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      onLongPress: onLongPress,
      radius: 24,
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Icon(icon, size: 21, color: DeckColors.textDim),
      ),
    );
  }
}
