/// Geometry for the overlapping card stack and the pull knob beside it.
///
/// The shape is a wallet: every card is drawn at full height, and they are
/// offset by less than that so each one slides under the next. What you see of
/// a covered card is its top strip — name and mark — with its lower half and
/// bottom corners hidden behind the card in front. That overlap is what makes
/// it read as a deck of cards rather than a list of coloured bars.
///
/// The focused card is the exception: everything after it is pushed clear of
/// its bottom edge, so it is revealed whole. The stack is clipped to its box,
/// which is what lets the tail card run off the bottom the way a real fanned
/// deck does.
///
/// Pure Dart, so it can be pinned down at the exact size this phone reports.
library;

class StackSpec {
  const StackSpec({
    required this.peek,
    required this.cardHeight,
    required this.cardCount,
    required this.focusedIndex,
    required this.originY,
    required this.boxHeight,
  });

  /// How much of a covered card stays visible: its top strip.
  final double peek;

  /// Every card is drawn this tall, focused or not — the covered ones are
  /// simply overlapped. Laying collapsed cards out at sliver height instead is
  /// what made them bars, and made their contents overflow.
  final double cardHeight;

  final int cardCount;
  final int focusedIndex;

  /// Top of the stack, so a short deck sits centred.
  final double originY;

  /// Height the stack was asked to fit into. When [totalHeight] exceeds it
  /// there are more cards than the box can hold at readable sizes, and the
  /// stack scrolls rather than crushing the strips.
  final double boxHeight;

  bool get overflows => totalHeight > boxHeight + 0.01;

  /// Total revealed height. The focused card is seen whole, everything else
  /// contributes its strip.
  double get totalHeight =>
      cardCount <= 0 ? 0 : cardHeight + (cardCount - 1) * peek;

  /// Top edge of card [index]. Cards up to and including the focused one are a
  /// strip apart; everything after it starts below the focused card's bottom.
  double topOf(int index) {
    final stripsAbove = index <= focusedIndex ? index : focusedIndex;
    final stripsBelow = index <= focusedIndex ? 0 : index - focusedIndex - 1;
    final clearsFocused = index > focusedIndex ? cardHeight : 0.0;
    return originY + stripsAbove * peek + clearsFocused + stripsBelow * peek;
  }

  /// Cards are all [cardHeight]; only how much of one is visible varies.
  double heightOf(int index) => cardHeight;

  /// What the eye actually gets of card [index].
  double revealOf(int index) => index == focusedIndex ? cardHeight : peek;
}

class StackStyle {
  const StackStyle({
    this.preferredPeek = 44,
    this.minPeek = 32,
    this.preferredCardHeight = 158,
    this.minCardHeight = 108,
  });

  final double preferredPeek;

  /// Never let the strip shrink below the card header, or the name in it gets
  /// clipped — which is exactly the overflow the first build shipped.
  final double minPeek;

  final double preferredCardHeight;
  final double minCardHeight;

  static const standard = StackStyle();

  /// The fixed top strip of a card: name on the left, mark on the right. Kept
  /// here because it is the floor [minPeek] has to respect.
  static const headerHeight = 32.0;
}

/// Fits [cardCount] overlapping cards into [height].
///
/// Squeezes the strips first, then the card itself, because a slightly shorter
/// card costs less than strips too thin to read a name in.
StackSpec solveStack({
  required double height,
  required int cardCount,
  required int focusedIndex,
  StackStyle style = StackStyle.standard,
}) {
  if (cardCount <= 0) {
    return StackSpec(
      peek: style.preferredPeek,
      cardHeight: style.preferredCardHeight,
      cardCount: 0,
      focusedIndex: 0,
      originY: 0,
      boxHeight: height,
    );
  }

  final safeIndex = focusedIndex.clamp(0, cardCount - 1);
  final strips = cardCount - 1;

  var cardHeight = style.preferredCardHeight;
  var peek = style.preferredPeek;

  if (strips > 0) {
    final spare = height - cardHeight;
    final fitted = spare / strips;
    if (fitted < peek) peek = fitted;

    if (peek < style.minPeek) {
      peek = style.minPeek;
      cardHeight = height - strips * peek;

      // If the card would now be below its floor there are simply more cards
      // than fit. Both floors hold and the stack overflows, to be scrolled —
      // strips too thin to read a name in are not a trade worth making, and
      // that crushing is what clipped the labels on the device.
      cardHeight = cardHeight.clamp(style.minCardHeight, double.infinity);
    }
  }

  cardHeight = cardHeight.clamp(style.minCardHeight, double.infinity);
  peek = peek.clamp(1.0, double.infinity);

  final total = cardHeight + strips * peek;
  final originY = total >= height ? 0.0 : (height - total) / 2;

  return StackSpec(
    peek: peek,
    cardHeight: cardHeight,
    cardCount: cardCount,
    focusedIndex: safeIndex,
    originY: originY,
    boxHeight: height,
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
