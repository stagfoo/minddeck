import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'stack_layout.dart';
import 'theme.dart';

/// The pull knob: this phone has no scroll wheel, so the deck gets a grip you
/// drag up and down the right edge instead.
///
/// The whole right band is the grab area, top to bottom — a thin track would
/// be a hairline target on a screen this small, and the thumb rests there
/// anyway. The track and grip drawn inside it are just the visible part of a
/// column that is draggable everywhere.
///
/// Deliberately physical — a ridged grip on a recessed track, sized to how
/// much deck there is, with a haptic tick as each card takes focus. It should
/// feel like a thing you pull, which is the only reason to have it rather than
/// a scrollbar.
class SideRail extends StatefulWidget {
  const SideRail({
    super.key,
    required this.cardCount,
    required this.focusedIndex,
    required this.onFocusChanged,
    required this.color,
  });

  final int cardCount;
  final int focusedIndex;
  final ValueChanged<int> onFocusChanged;

  /// The focused card's colour. The grip wears it, so the rail says which card
  /// you are on even while your thumb is covering the deck.
  final Color color;

  @override
  State<SideRail> createState() => _SideRailState();
}

class _SideRailState extends State<SideRail> {
  bool _dragging = false;

  /// The card this rail last ticked for.
  ///
  /// Comparing against widget.focusedIndex alone assumed the parent had already
  /// rebuilt with the new index before the next drag update arrived. It has
  /// not, mid-gesture — so a slow thumb crossing one boundary ticked on every
  /// frame after it rather than once. The rail keeps its own count so a tick
  /// never waits on a round trip.
  int? _lastTicked;

  @override
  void didUpdateWidget(SideRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Focus moved somewhere else — a swipe on the stack, the deck reloading —
    // so the rail's own count follows rather than suppressing the next tick.
    if (oldWidget.focusedIndex != widget.focusedIndex) {
      _lastTicked = widget.focusedIndex;
    }
  }

  void _select(double y, double trackHeight) {
    final index = cardIndexForKnobPosition(
      y: y,
      trackHeight: trackHeight,
      cardCount: widget.cardCount,
    );
    if (index == (_lastTicked ?? widget.focusedIndex)) return;
    _lastTicked = index;
    _tick();
    widget.onFocusChanged(index);
  }

  /// One tick per card the grip passes, so the deck feels like it has detents
  /// rather than sliding.
  ///
  /// The system click rather than a bundled sound: it is the tick Android
  /// already uses, it needs no asset or audio plugin, and it obeys the phone's
  /// touch-sounds setting — so "subtle" includes silent for anyone who has
  /// turned those off, without this needing a setting of its own.
  void _tick() {
    HapticFeedback.selectionClick();
    SystemSound.play(SystemSoundType.click);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: DeckMetrics.railWidth,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackHeight = constraints.maxHeight;
          final knob = solveKnob(
            trackHeight: trackHeight,
            cardCount: widget.cardCount,
            focusedIndex: widget.focusedIndex,
          );

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragStart: (details) {
              setState(() => _dragging = true);
              _select(details.localPosition.dy, trackHeight);
            },
            onVerticalDragUpdate: (details) =>
                _select(details.localPosition.dy, trackHeight),
            onVerticalDragEnd: (_) => setState(() => _dragging = false),
            onVerticalDragCancel: () => setState(() => _dragging = false),
            // Tapping the track jumps the knob there, the way a scrollbar
            // gutter does — dragging is not the only way to move.
            onTapDown: (details) => _select(details.localPosition.dy, trackHeight),
            child: Stack(
              children: [
                Center(
                  child: Container(
                    width: 30,
                    decoration: BoxDecoration(
                      color: DeckColors.surface,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: DeckColors.surfaceEdge),
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: _dragging
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  top: knob.top,
                  height: knob.height,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _Knob(active: _dragging, color: widget.color),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Knob extends StatelessWidget {
  const _Knob({required this.active, required this.color});

  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      // The colour is animated by the same container that animates the width,
      // so moving between cards cross-fades the grip rather than snapping it.
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: active ? 34 : 30,
      height: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          // Every palette colour is chosen to carry black, so a dark rim reads
          // on all of them; while dragging it lifts to white for the grabbed
          // state instead of inventing a second hue.
          color: active
              ? Colors.white.withValues(alpha: 0.85)
              : DeckColors.ground.withValues(alpha: 0.55),
          width: active ? 2 : 1,
        ),
        boxShadow: active
            ? [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 16)]
            : null,
      ),
      child: const _Ridges(),
    );
  }
}

/// Three ridges across the grip. Purely decorative, and the whole reason the
/// knob reads as something to pull rather than a plain pill.
class _Ridges extends StatelessWidget {
  const _Ridges();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              width: 14,
              height: 2,
              margin: const EdgeInsets.symmetric(vertical: 2.5),
              decoration: BoxDecoration(
                color: DeckColors.ground.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
        ],
      ),
    );
  }
}
