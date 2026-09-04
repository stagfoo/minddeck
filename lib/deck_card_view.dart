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
/// The name sits in a fixed strip at the card's *bottom* edge, because that is
/// the part left visible when the card in front covers it. It holds everything
/// needed to identify the card: name, count and mark.
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
    this.arranging = false,
    this.wigglePhase = 0,
    this.lifted = false,
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

  /// While arranging, the card shows only its name strip and wiggles. Its app
  /// row is hidden — arrange mode is about position, and a row of tappable
  /// icons inside something you are dragging is only a way to misfire.
  final bool arranging;

  /// Offsets each card's wiggle so the deck doesn't pulse in unison.
  final double wigglePhase;

  /// This is the card currently under the finger.
  final bool lifted;

  @override
  Widget build(BuildContext context) {
    final color = colorOf(card.colorKey);
    final card_ = GestureDetector(
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
              color: Colors.black.withValues(alpha: lifted ? 0.7 : (focused ? 0.55 : 0.4)),
              blurRadius: lifted ? 26 : (focused ? 20 : 10),
              offset: Offset(0, lifted ? 12 : (focused ? 8 : 3)),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: arranging ? const SizedBox() : _body(color)),
            _nameStrip(),
          ],
        ),
      ),
    );

    if (!arranging || card.isAllApps || lifted) return card_;
    return Transform.rotate(angle: wigglePhase, child: card_);
  }

  /// The strip that stays visible when this card is covered.
  Widget _nameStrip() {
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
                style: deckText(
                  size: 16,
                  weight: 700,
                  color: DeckColors.onCard,
                  letterSpacing: -0.3,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              card.isAllApps ? '$totalInstalled' : '${apps.length}',
              style: deckText(
                size: 12,
                weight: 700,
                color: DeckColors.onCard.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              arranging && !card.isAllApps
                  ? Icons.drag_indicator_rounded
                  : iconOf(card.iconKey),
              size: 17,
              color: DeckColors.onCard,
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(Color color) {
    if (apps.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            card.isAllApps ? 'nothing installed' : 'empty — hold to fill',
            style: deckText(
              size: 12,
              weight: 500,
              color: DeckColors.onCard.withValues(alpha: 0.5),
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
