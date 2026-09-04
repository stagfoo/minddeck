import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolidecks/theme.dart';

/// Measures a line of text laid out with [style].
Size measure(TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: 'Handgloves media daily', style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  return painter.size;
}

void main() {
  // flutter test renders with a placeholder font whose glyphs all have the
  // same advance width, so without loading the real file every weight measures
  // identically and the test below would pass no matter what.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final bytes = File('assets/fonts/Lexend[wght].ttf').readAsBytesSync();
    await (FontLoader('Lexend')
          ..addFont(Future.value(ByteData.view(bytes.buffer))))
        .load();
  });

  // Lexend is a single variable font with a wght axis, so every weight comes
  // from the same file. This measures that the axis is actually driven —
  // heavier text is wider — rather than trusting it, which is the failure that
  // would otherwise look like "the font just doesn't have a bold".
  test('weights actually differ, not just nominally', () {
    final light = measure(deckText(size: 20, weight: 300));
    final regular = measure(deckText(size: 20, weight: 400));
    final bold = measure(deckText(size: 20, weight: 700));

    expect(regular.width, greaterThan(light.width));
    expect(bold.width, greaterThan(regular.width));
  });

  test('deckText carries the family through', () {
    expect(deckText(size: 12).fontFamily, 'Lexend');
  });

  test('the weight lands on both the axis and the nominal weight', () {
    // fontVariations drives the variable axis; fontWeight keeps fallback fonts
    // and any synthesis honest.
    final style = deckText(size: 12, weight: 600);
    expect(style.fontWeight, FontWeight.w600);
    expect(
      style.fontVariations?.any((v) => v.axis == 'wght' && v.value == 600),
      isTrue,
    );
  });
}
