import 'package:flutter_test/flutter_test.dart';
import 'package:rolidecks/models.dart';

void main() {
  group('ScreenMetrics', () {
    test('converts the measured panel into dp', () {
      // The Mind One in landscape, at the density it is expected to report.
      const metrics = ScreenMetrics(
        widthPx: 1240,
        heightPx: 1080,
        density: 2.75,
        densityDpi: 440,
      );
      expect(metrics.widthDp.round(), 451);
      expect(metrics.heightDp.round(), 393);
    });

    test('reports how far from square the panel is', () {
      const metrics = ScreenMetrics(
        widthPx: 1240,
        heightPx: 1080,
        density: 2.75,
        densityDpi: 440,
      );
      // Nowhere near the 16:9 a Switch-style layout normally assumes.
      expect(metrics.aspectRatio, closeTo(1.148, 0.001));
      expect(metrics.aspectRatio, lessThan(1.3));
    });

    test('reads back what the platform sent', () {
      final metrics = ScreenMetrics.fromPlatform({
        'widthPx': 1080,
        'heightPx': 1240,
        'density': 2.75,
        'densityDpi': 440,
      });
      expect(metrics.widthPx, 1080);
      expect(metrics.heightPx, 1240);
      expect(metrics.density, 2.75);
    });

    test('survives a platform map with nothing in it', () {
      final metrics = ScreenMetrics.fromPlatform(const {});
      expect(metrics.widthPx, 0);
      // Density must never be zero — dp conversion divides by it.
      expect(metrics.density, 1);
      expect(metrics.widthDp, 0);
    });
  });
}
