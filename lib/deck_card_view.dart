import 'package:flutter/material.dart';

import 'card_deck.dart';
import 'theme.dart';

/// One card in the stack.
///
/// Collapsed it is a coloured sliver showing its icon and name; focused it
/// opens to full height and shows how much is filed on it. The name sits right
/// -aligned against the icon, which is the rabbitOS arrangement and reads well
/// at sliver height.
class DeckCardView extends StatelessWidget {
  const DeckCardView({
    super.key,
    required this.card,
    required this.height,
    required this.focused,
    required this.appCount,
    required this.onTap,
    this.onLongPress,
  });

  final DeckCard card;
  final double height;
  final bool focused;
  final int appCount;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final color = colorOf(card.colorKey);
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(DeckMetrics.cardRadius),
          boxShadow: focused
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.45),
                    blurRadius: 22,
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(iconOf(card.iconKey), size: 19, color: DeckColors.onCard),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      card.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: DeckColors.onCard,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
              if (focused) ...[
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      card.isAllApps
                          ? '$appCount installed'
                          : appCount == 0
                              ? 'empty — tap to fill'
                              : '$appCount ${appCount == 1 ? 'app' : 'apps'}',
                      style: TextStyle(
                        color: DeckColors.onCard.withValues(alpha: 0.62),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 20, color: DeckColors.onCard),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
