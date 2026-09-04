import 'package:flutter/material.dart';

import 'card_style.dart';
import 'theme.dart';

/// Any colour for a card, not just the twelve.
///
/// Returns a colour key: a palette name if a preset was tapped, or a `#rrggbb`
/// literal for a custom one, so storage does not have to know the difference.
Future<String?> showColorPicker(
  BuildContext context, {
  required String current,
  required String cardName,
  required String iconKey,
}) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(
      builder: (context) => ColorPickerScreen(
        current: current,
        cardName: cardName,
        iconKey: iconKey,
      ),
    ),
  );
}

class ColorPickerScreen extends StatefulWidget {
  const ColorPickerScreen({
    super.key,
    required this.current,
    required this.cardName,
    required this.iconKey,
  });

  final String current;
  final String cardName;
  final String iconKey;

  @override
  State<ColorPickerScreen> createState() => _ColorPickerScreenState();
}

class _ColorPickerScreenState extends State<ColorPickerScreen> {
  late HSVColor _hsv = HSVColor.fromColor(colorOf(widget.current));

  Color get _color => _hsv.toColor();

  String get _key {
    // A custom colour that lands exactly on a palette entry is stored as that
    // palette entry, so retuning the palette later still restyles it.
    final argb = _color.toARGB32();
    for (final entry in cardPalette) {
      if (entry.value == argb) return entry.key;
    }
    return customColorKey(argb);
  }

  @override
  Widget build(BuildContext context) {
    final onCard = onCardFor(_color);

    return Scaffold(
      backgroundColor: DeckColors.ground,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.arrow_back_rounded,
                        size: 22, color: DeckColors.text),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('Colour', style: deckText(size: 16, weight: 600)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, _key),
                  child: Text('Use it',
                      style: deckText(size: 13, weight: 600, color: _color)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // The card as it will actually look, foreground and all — a swatch
            // alone does not tell you whether the name will still read on it.
            Container(
              height: 92,
              decoration: BoxDecoration(
                color: _color,
                borderRadius: BorderRadius.circular(DeckMetrics.cardRadius),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.cardName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: deckText(size: 16, weight: 700, color: onCard),
                        ),
                      ),
                      Icon(iconOf(widget.iconKey), size: 17, color: onCard),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _label('Presets'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final entry in cardPalette)
                  GestureDetector(
                    onTap: () => Navigator.pop(context, entry.key),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Color(entry.value),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: entry.key == widget.current
                              ? DeckColors.text
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            _label('Custom'),
            const SizedBox(height: 4),
            _slider(
              'Hue',
              _hsv.hue / 360,
              [for (var i = 0; i <= 360; i += 30) HSVColor.fromAHSV(1, i.toDouble() % 360, 1, 1).toColor()],
              (value) => setState(() => _hsv = _hsv.withHue(value * 360)),
            ),
            _slider(
              'Saturation',
              _hsv.saturation,
              [_hsv.withSaturation(0).toColor(), _hsv.withSaturation(1).toColor()],
              (value) => setState(() => _hsv = _hsv.withSaturation(value)),
            ),
            _slider(
              'Brightness',
              _hsv.value,
              [_hsv.withValue(0).toColor(), _hsv.withValue(1).toColor()],
              (value) => setState(() => _hsv = _hsv.withValue(value)),
            ),
            const SizedBox(height: 6),
            Text(
              // Shown because it is what gets stored, and because a colour you
              // liked once is worth being able to write down.
              customColorKey(_color.toARGB32()).toUpperCase(),
              style: deckText(size: 12, color: DeckColors.textDim),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: deckText(
          size: 11,
          weight: 600,
          color: DeckColors.textDim,
          letterSpacing: 0.8,
        ),
      );

  Widget _slider(
    String name,
    double value,
    List<Color> track,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: deckText(size: 11, color: DeckColors.textDim)),
          const SizedBox(height: 2),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: LinearGradient(colors: track),
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 12,
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  thumbColor: DeckColors.text,
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                ),
                child: Slider(value: value, onChanged: onChanged),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
