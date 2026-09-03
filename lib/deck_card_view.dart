import 'package:flutter/material.dart';

import 'card_deck.dart';
import 'card_row.dart';
import 'models.dart';
import 'stack_layout.dart';
import 'theme.dart';

/// One card in the stack.
///
/// Always drawn at full height — what changes between focused and covered is
/// only how much of it the card in front leaves visible. That is what makes
/// the deck read as overlapping cards, and it means a covered card never has
/// to squeeze its contents into a sliver.
///
/// The header is the fixed top strip: name on the left, mark on the right,
/// like the title row of a real card. It is the part that stays visible when
/// the card is covered, so it holds everything you need to identify it.
class DeckCardView extends StatelessWidget {
  const DeckCardView({
    super.key,
    required this.card,
    required this.height,
    required this.focused,
    required this.apps,
    required this.totalInstalled,
    required this.onTap,
    required this.onAppTap,
    this.onLongPress,
    this.onAppLongPress,
  });

  final DeckCard card;
  final double height;
  final bool focused;
  final List<LaunchableApp> apps;
  final int totalInstalled;
  final VoidCallback onTap;
  final ValueChanged<LaunchableApp> onAppTap;
  final VoidCallback? onLongPress;
  final ValueChanged<LaunchableApp>? onAppLongPress;

  @override
  Widget build(BuildContext context) {
    final color = colorOf(card.colorKey);
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(DeckMetrics.cardRadius),
          // A covered card casts a shadow onto the one behind it. Without this
          // the overlap reads as flat stripes rather than stacked cards.
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: focused ? 0.55 : 0.4),
              blurRadius: focused ? 20 : 10,
              offset: Offset(0, focused ? 8 : 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(),
            Expanded(child: _body(color)),
          ],
        ),
      ),
    );
  }

  /// The strip that stays visible when this card is covered.
  Widget _header() {
    return SizedBox(
      height: StackStyle.headerHeight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 12, 0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                card.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: DeckColors.onCard,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              card.isAllApps ? '$totalInstalled' : '${apps.length}',
              style: TextStyle(
                color: DeckColors.onCard.withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Icon(iconOf(card.iconKey), size: 17, color: DeckColors.onCard),
          ],
        ),
      ),
    );
  }

  Widget _body(Color color) {
    if (apps.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            card.isAllApps ? 'nothing installed' : 'empty — hold to fill',
            style: TextStyle(
              color: DeckColors.onCard.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }
    return CardAppRow(
      apps: apps,
      cardColor: color,
      onTap: onAppTap,
      onLongPress: onAppLongPress,
    );
  }
}
