import 'package:flutter_test/flutter_test.dart';
import 'package:minddeck/grid_layout.dart';

void main() {
  // The Mind One in landscape: 1240 × 1080 physical. At a 2.75 density that is
  // about 451 × 393 dp; the deck area is what's left after the status strip and
  // the system row.
  const deckWidth = 451.0;
  const deckHeight = 300.0;

  group('solveGrid on the Mind One panel', () {
    test('fills the near-square deck with more than one row', () {
      // The whole point of not copying the Switch literally: a single row would
      // waste this panel's height.
      final grid = solveGrid(width: deckWidth, height: deckHeight);
      expect(grid.rows, greaterThan(1));
      expect(grid.columns, greaterThan(1));
    });

    test('keeps tiles near the target size rather than filling blindly', () {
      final grid = solveGrid(width: deckWidth, height: deckHeight);
      expect(grid.tileSize, greaterThan(90));
      expect(grid.tileSize, lessThan(150));
    });

    test('the grid fits inside the box it was given', () {
      final grid = solveGrid(width: deckWidth, height: deckHeight);
      expect(grid.contentWidth, lessThanOrEqualTo(deckWidth + 0.01));
      expect(grid.contentHeight, lessThanOrEqualTo(deckHeight + 0.01));
    });

    test('is centred, with equal slack on both sides', () {
      final grid = solveGrid(width: deckWidth, height: deckHeight);
      expect(grid.originX, closeTo((deckWidth - grid.contentWidth) / 2, 0.01));
      expect(grid.originY, closeTo((deckHeight - grid.contentHeight) / 2, 0.01));
    });
  });

  group('positionOf', () {
    test('lays tiles left to right, then wraps to the next row', () {
      final grid = solveGrid(width: 400, height: 400);
      final first = grid.positionOf(0);
      final second = grid.positionOf(1);
      expect(second.x, closeTo(first.x + grid.tileSize + grid.gap, 0.01));
      expect(second.y, first.y);

      final firstOfNextRow = grid.positionOf(grid.columns);
      expect(firstOfNextRow.x, closeTo(first.x, 0.01));
      expect(firstOfNextRow.y, closeTo(first.y + grid.tileSize + grid.gap, 0.01));
    });

    test('the last tile of a full grid still lands inside the box', () {
      const width = 451.0;
      const height = 300.0;
      final grid = solveGrid(width: width, height: height);
      final last = grid.positionOf(grid.capacity - 1);
      expect(last.x + grid.tileSize, lessThanOrEqualTo(width + 0.01));
      expect(last.y + grid.tileSize, lessThanOrEqualTo(height + 0.01));
    });
  });

  group('degenerate boxes', () {
    test('a very wide box does not produce absurdly large tiles', () {
      final grid = solveGrid(width: 2000, height: 400);
      expect(grid.tileSize, lessThanOrEqualTo(GridStyle.standard.maxTileSize));
      expect(grid.columns, lessThanOrEqualTo(GridStyle.standard.maxColumns));
    });

    test('a box narrower than one tile still yields a usable grid', () {
      // Better a cramped launcher than one that lays out at zero and shows
      // nothing at all.
      final grid = solveGrid(width: 40, height: 400);
      expect(grid.columns, greaterThanOrEqualTo(1));
      expect(grid.tileSize, greaterThan(0));
      expect(grid.capacity, greaterThan(0));
    });

    test('a box shorter than one tile keeps a single row', () {
      final grid = solveGrid(width: 451, height: 50);
      expect(grid.rows, 1);
      expect(grid.tileSize, greaterThan(0));
      expect(grid.capacity, greaterThan(0));
    });

    test('a zero-sized box does not crash or return negative geometry', () {
      final grid = solveGrid(width: 0, height: 0);
      expect(grid.tileSize, greaterThan(0));
      expect(grid.rows, greaterThanOrEqualTo(1));
      expect(grid.capacity, greaterThan(0));
    });
  });

  group('style', () {
    test('a bigger target tile yields fewer, larger tiles', () {
      final small = solveGrid(
        width: deckWidth,
        height: deckHeight,
        style: const GridStyle(targetTileSize: 80),
      );
      final large = solveGrid(
        width: deckWidth,
        height: deckHeight,
        style: const GridStyle(targetTileSize: 150),
      );
      expect(large.tileSize, greaterThan(small.tileSize));
      expect(large.columns, lessThan(small.columns));
    });

    test('respects the column bounds it was given', () {
      final grid = solveGrid(
        width: deckWidth,
        height: deckHeight,
        style: const GridStyle(minColumns: 3, maxColumns: 3),
      );
      expect(grid.columns, 3);
    });
  });
}
