/// Geometry for the card stack and the pull knob beside it.
///
/// The stack is the rabbitOS shape: one focused card open to full height, the
/// rest collapsed to a title-bar sliver below and above it, overlapping so the
/// whole deck stays on screen without scrolling. The knob is the substitute
/// for the scroll wheel this phone doesn't have — a track down the right edge
/// with a grip you drag to move focus.
///
/// Pure Dart, so it can be pinned down at the exact size this phone reports.
library;

class StackSpec {
  const StackSpec({
    required this.peek,
    required this.focusedHeight,
    required this.cardCount,
    required this.focusedIndex,
    required this.originY,
  });

  /// Visible slice of a collapsed card — enough for its icon and name.
  final double peek;

  /// Height of the one open card.
  final double focusedHeight;

  final int cardCount;
  final int focusedIndex;

  /// Top of the stack, so it sits centred when the deck is short.
  final double originY;

  double get totalHeight =>
      cardCount <= 0 ? 0 : focusedHeight + (cardCount - 1) * peek;

  /// Top edge of the card at [index]. Cards above the focused one are stacked
  /// at [peek] intervals; everything below is pushed down by the open card.
  double topOf(int index) {
    final above = index <= focusedIndex ? index : focusedIndex;
    final below = index <= focusedIndex ? 0 : index - focusedIndex - 1;
    return originY + above * peek + (index > focusedIndex ? focusedHeight : 0) + below * peek;
  }

  double heightOf(int index) => index == focusedIndex ? focusedHeight : peek;
}

class StackStyle {
  const StackStyle({
    this.preferredPeek = 42,
    this.minPeek = 26,
    this.preferredFocusedHeight = 150,
    this.minFocusedHeight = 92,
  });

  final double preferredPeek;
  final double minPeek;
  final double preferredFocusedHeight;
  final double minFocusedHeight;

  static const standard = StackStyle();
}

/// Fits [cardCount] cards into [height], shrinking the collapsed slivers first
/// and the open card only if that isn't enough.
///
/// Never returns a stack taller than the box: the whole point of the shape is
/// that the deck is always fully visible, so overflow would be a bug rather
/// than something to scroll.
StackSpec solveStack({
  required double height,
  required int cardCount,
  required int focusedIndex,
  StackStyle style = StackStyle.standard,
}) {
  if (cardCount <= 0) {
    return StackSpec(
      peek: style.preferredPeek,
      focusedHeight: style.preferredFocusedHeight,
      cardCount: 0,
      focusedIndex: 0,
      originY: 0,
    );
  }

  final safeIndex = focusedIndex.clamp(0, cardCount - 1);
  final collapsed = cardCount - 1;

  var focusedHeight = style.preferredFocusedHeight;
  var peek = style.preferredPeek;

  if (collapsed > 0) {
    final spare = height - focusedHeight;
    final fitted = spare / collapsed;
    if (fitted < peek) peek = fitted;
  }

  if (peek < style.minPeek) {
    // Too many cards for comfortable slivers: hold the sliver at its minimum
    // and take the difference out of the open card instead, which degrades
    // more gracefully than unreadable slivers.
    peek = style.minPeek;
    focusedHeight = height - collapsed * peek;
  }

  focusedHeight = focusedHeight.clamp(style.minFocusedHeight, double.infinity);
  peek = peek.clamp(1.0, double.infinity);

  final total = focusedHeight + collapsed * peek;
  final originY = total >= height ? 0.0 : (height - total) / 2;

  return StackSpec(
    peek: peek,
    focusedHeight: focusedHeight,
    cardCount: cardCount,
    focusedIndex: safeIndex,
    originY: originY,
  );
}

/// Where the grip sits on its track, and how big it is.
class KnobSpec {
  const KnobSpec({required this.top, required this.height, required this.trackHeight});

  final double top;
  final double height;
  final double trackHeight;

  double get center => top + height / 2;
}

/// The knob shrinks as the deck grows, the way a scrollbar thumb does, so its
/// size reads as "how much deck there is" without any extra chrome.
KnobSpec solveKnob({
  required double trackHeight,
  required int cardCount,
  required int focusedIndex,
  double minHeight = 44,
}) {
  if (cardCount <= 1 || trackHeight <= 0) {
    return KnobSpec(
      top: 0,
      height: trackHeight <= 0 ? 0 : trackHeight,
      trackHeight: trackHeight,
    );
  }
  final proportional = trackHeight / cardCount;
  final floor = minHeight.clamp(0.0, trackHeight);
  final height = proportional.clamp(floor, trackHeight);
  final travel = trackHeight - height;
  final safeIndex = focusedIndex.clamp(0, cardCount - 1);
  return KnobSpec(
    top: travel * (safeIndex / (cardCount - 1)),
    height: height,
    trackHeight: trackHeight,
  );
}

/// Which card a drag to [y] on the track selects.
///
/// Uses the knob's own travel rather than the raw track, so the card under the
/// grip matches where the grip actually is — dividing the bare track into equal
/// bands would drift, because the knob can't reach the last band's top.
int cardIndexForKnobPosition({
  required double y,
  required double trackHeight,
  required int cardCount,
  double minHeight = 44,
}) {
  if (cardCount <= 1) return 0;
  final knob = solveKnob(
    trackHeight: trackHeight,
    cardCount: cardCount,
    focusedIndex: 0,
    minHeight: minHeight,
  );
  final travel = trackHeight - knob.height;
  if (travel <= 0) return 0;
  final centred = (y - knob.height / 2).clamp(0.0, travel);
  return (centred / travel * (cardCount - 1)).round().clamp(0, cardCount - 1);
}
