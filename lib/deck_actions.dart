import 'package:flutter/material.dart';

import 'theme.dart';

/// Add a card, and open Android's settings.
///
/// Along the bottom-left rather than the top, so nothing sits above the deck.
/// A bar over the stack reads as a gap the cards start below, which undoes the
/// impression that they are a deck resting on the screen — and the top edge is
/// where the front card belongs. Down here the row shares the space the system
/// gesture bar already occupies.
class DeckActions extends StatelessWidget {
  const DeckActions({
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
      height: DeckMetrics.actionsHeight,
      child: Padding(
        padding: const EdgeInsets.only(left: DeckMetrics.gutter - 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _ActionButton(icon: Icons.add_rounded, onTap: onAdd),
            const SizedBox(width: 2),
            _ActionButton(
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.onTap, this.onLongPress});

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
