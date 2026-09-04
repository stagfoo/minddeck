import 'package:flutter/material.dart';

import 'card_deck.dart';
import 'models.dart';
import 'theme.dart';

/// Picks apps to put on a card.
///
/// Multi-select, because filing a card's worth of apps one sheet at a time is
/// the tedious way to set a launcher up. Apps already filed elsewhere are shown
/// with the card they are on, so moving one is a deliberate choice rather than
/// a surprise.
Future<List<String>?> showAppPicker(
  BuildContext context, {
  required DeckCard card,
  required CardDeck deck,
  required List<LaunchableApp> installed,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    backgroundColor: DeckColors.strip,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _AppPickerSheet(
      card: card,
      deck: deck,
      installed: installed,
    ),
  );
}

class _AppPickerSheet extends StatefulWidget {
  const _AppPickerSheet({
    required this.card,
    required this.deck,
    required this.installed,
  });

  final DeckCard card;
  final CardDeck deck;
  final List<LaunchableApp> installed;

  @override
  State<_AppPickerSheet> createState() => _AppPickerSheetState();
}

class _AppPickerSheetState extends State<_AppPickerSheet> {
  final _chosen = <String>{};
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.installed]..sort(compareByLabel);
    final matches = searchApps(sorted, _query);
    final color = colorOf(widget.card.colorKey);

    return ConstrainedBox(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.88),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(iconOf(widget.card.iconKey),
                        size: 15, color: DeckColors.onCard),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Add to ${widget.card.name}',
                      style: const TextStyle(
                          color: DeckColors.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: TextField(
                style: const TextStyle(color: DeckColors.text, fontSize: 14),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: DeckColors.surface,
                  hintText: 'Search ${widget.installed.length} apps',
                  hintStyle:
                      const TextStyle(color: DeckColors.textDim, fontSize: 13),
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
            Flexible(
              child: matches.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(28),
                      child: Text('Nothing matches',
                          style: TextStyle(color: DeckColors.textDim)),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final app = matches[index];
                        return _row(app, color);
                      },
                    ),
            ),
            const Divider(height: 1, color: DeckColors.surfaceEdge),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _chosen.isEmpty
                      ? null
                      : () => Navigator.pop(context, _chosen.toList()),
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: DeckColors.onCard,
                    disabledBackgroundColor: DeckColors.surface,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: Text(
                    _chosen.isEmpty
                        ? 'Pick some apps'
                        : 'Add ${_chosen.length}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(LaunchableApp app, Color color) {
    final chosen = _chosen.contains(app.id);
    final alreadyHere = widget.card.appIds.contains(app.id);
    final elsewhere = widget.deck.cardIdFor(app.id);
    final elsewhereName = elsewhere == null || elsewhere == widget.card.id
        ? null
        : widget.deck.folders
            .firstWhere((entry) => entry.id == elsewhere)
            .name;

    return ListTile(
      dense: true,
      enabled: !alreadyHere,
      leading: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: chosen ? color : DeckColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: chosen ? color : DeckColors.surfaceEdge,
          ),
        ),
        child: chosen
            ? const Icon(Icons.check, size: 17, color: DeckColors.onCard)
            : null,
      ),
      title: Text(
        app.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: alreadyHere ? DeckColors.textDim : DeckColors.text,
          fontSize: 14,
        ),
      ),
      subtitle: alreadyHere
          ? const Text('already on this card',
              style: TextStyle(color: DeckColors.textDim, fontSize: 11))
          : elsewhereName == null
              ? null
              : Text('on $elsewhereName — will move here',
                  style: const TextStyle(
                      color: DeckColors.textDim, fontSize: 11)),
      onTap: alreadyHere
          ? null
          : () => setState(() {
                if (!_chosen.remove(app.id)) _chosen.add(app.id);
              }),
    );
  }
}
