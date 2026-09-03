/// Works out the tile grid for whatever box the launcher is given.
///
/// A Switch home screen is one horizontal row of large squares because a TV is
/// 16:9. This panel is about 1.15:1 — near square — so a single row would
/// leave most of the height empty and shrink the tiles for no reason. The
/// layout instead picks the column count that gets tiles closest to a target
/// size, and fills the height with rows.
///
/// Pure Dart, so the geometry can be pinned down in tests at the exact sizes
/// this phone reports rather than eyeballed on a device.
library;

class GridSpec {
  const GridSpec({
    required this.columns,
    required this.rows,
    required this.tileSize,
    required this.gap,
    required this.originX,
    required this.originY,
  });

  final int columns;
  final int rows;

  /// Tiles are square — the Switch's rounded-square card is the whole look.
  final double tileSize;

  final double gap;

  /// Left/top offset that centres the grid in its box.
  final double originX;
  final double originY;

  int get capacity => columns * rows;

  double get contentWidth => columns * tileSize + (columns - 1) * gap;

  double get contentHeight => rows * tileSize + (rows - 1) * gap;

  /// Top-left of the tile at [index], laid out left-to-right then top-to-bottom.
  ({double x, double y}) positionOf(int index) {
    final column = index % columns;
    final row = index ~/ columns;
    return (
      x: originX + column * (tileSize + gap),
      y: originY + row * (tileSize + gap),
    );
  }
}

/// Tuning knobs, kept separate so a different device or taste is a value
/// change rather than an edit to the solver.
class GridStyle {
  const GridStyle({
    this.targetTileSize = 116,
    this.minTileSize = 68,
    this.maxTileSize = 168,
    this.gap = 14,
    this.minColumns = 2,
    this.maxColumns = 6,
  });

  /// What a tile "wants" to be. The Switch's cards are large and few; this is
  /// the number that decides how console-like the grid feels.
  final double targetTileSize;

  final double minTileSize;
  final double maxTileSize;
  final double gap;
  final int minColumns;
  final int maxColumns;

  static const standard = GridStyle();
}

/// Solves the grid for a [width] × [height] box.
///
/// Picks the column count whose resulting tile size lands closest to
/// [GridStyle.targetTileSize], then fits as many whole rows as the height
/// allows. Never returns a zero-tile grid: a launcher with no tiles is worse
/// than a cramped one.
GridSpec solveGrid({
  required double width,
  required double height,
  GridStyle style = GridStyle.standard,
}) {
  final gap = style.gap;

  var bestColumns = style.minColumns;
  var bestTile = 0.0;
  var bestDistance = double.infinity;

  for (var columns = style.minColumns; columns <= style.maxColumns; columns++) {
    final tile = (width - gap * (columns - 1)) / columns;
    if (tile < style.minTileSize && columns > style.minColumns) continue;
    final clamped = tile.clamp(style.minTileSize, style.maxTileSize);
    final distance = (clamped - style.targetTileSize).abs();
    if (distance < bestDistance) {
      bestDistance = distance;
      bestColumns = columns;
      bestTile = clamped;
    }
  }

  // Narrower than one minimum tile: give back a single tile that fits rather
  // than a negative size.
  if (bestTile <= 0) {
    bestTile = width.clamp(1.0, style.maxTileSize);
    bestColumns = 1;
  }

  var rows = ((height + gap) / (bestTile + gap)).floor();
  if (rows < 1) {
    // Not even one target-sized row fits — shrink the tile to the height
    // instead of dropping to zero rows.
    rows = 1;
    bestTile = bestTile.clamp(1.0, height <= 0 ? 1.0 : height);
  }

  final contentWidth = bestColumns * bestTile + (bestColumns - 1) * gap;
  final contentHeight = rows * bestTile + (rows - 1) * gap;

  return GridSpec(
    columns: bestColumns,
    rows: rows,
    tileSize: bestTile,
    gap: gap,
    originX: (width - contentWidth) / 2,
    originY: (height - contentHeight) / 2,
  );
}
