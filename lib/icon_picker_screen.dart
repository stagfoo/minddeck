import 'package:flutter/material.dart';

import 'card_style.dart';
import 'icon_catalogue.dart';
import 'theme.dart';

/// Every Material icon, searchable.
///
/// A full screen rather than a sheet: two thousand icons need room and a
/// keyboard, and the card editor is itself a sheet — stacking one on another
/// leaves almost nothing for the grid.
Future<String?> showIconPicker(
  BuildContext context, {
  required String current,
  required Color accent,
}) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(
      builder: (context) => IconPickerScreen(current: current, accent: accent),
    ),
  );
}

class IconPickerScreen extends StatefulWidget {
  const IconPickerScreen({
    super.key,
    required this.current,
    required this.accent,
  });

  final String current;
  final Color accent;

  @override
  State<IconPickerScreen> createState() => _IconPickerScreenState();
}

class _IconPickerScreenState extends State<IconPickerScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final matches = searchIcons(_query);
    final searching = _query.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: DeckColors.ground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
              child: Row(
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
                    child: Text('Icon', style: deckText(size: 16, weight: 600)),
                  ),
                  Text(
                    searching
                        ? '${matches.length}'
                        : '${materialIcons.length} in all',
                    style: deckText(size: 12, color: DeckColors.textDim),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: TextField(
                autofocus: true,
                style: deckText(size: 14),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: DeckColors.surface,
                  hintText: 'Search icons',
                  hintStyle: deckText(size: 13, color: DeckColors.textDim),
                  prefixIcon: const Icon(Icons.search,
                      size: 18, color: DeckColors.textDim),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            if (!searching)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Common',
                      style: deckText(size: 11, color: DeckColors.textDim)),
                ),
              ),
            Expanded(
              child: matches.isEmpty
                  ? Center(
                      child: Text('No icon called that',
                          style: deckText(size: 13, color: DeckColors.textDim)),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 64,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: matches.length,
                      itemBuilder: (context, index) => _tile(matches[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(String key) {
    final chosen = key == widget.current;
    return GestureDetector(
      onTap: () => Navigator.pop(context, key),
      child: Container(
        decoration: BoxDecoration(
          color: chosen ? widget.accent : DeckColors.surface,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: chosen ? widget.accent : DeckColors.surfaceEdge,
          ),
        ),
        child: Icon(
          iconOf(key),
          size: 22,
          color: chosen ? DeckColors.onCard : DeckColors.text,
        ),
      ),
    );
  }
}
