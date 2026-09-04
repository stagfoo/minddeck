import 'package:flutter/material.dart';

import 'card_deck.dart';
import 'models.dart';
import 'theme.dart';

/// Picks apps to put on a card.
///
/// A full screen rather than a bottom sheet. On a screen this short the sheet
/// had to fight the keyboard for room, and the trick it used — folding the
/// title away once the keyboard was up — changed the number of children in the
/// column, which shifted the search field's position in it. Flutter matches
/// unkeyed children by position, so the field's element was rebuilt against the
/// title's, losing focus and closing the keyboard the moment it opened. A full
/// screen has the room, so nothing has to move.
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
  return Navigator.of(context).push<List<String>>(
    MaterialPageRoute(
      builder: (context) =>
          AppPickerScreen(card: card, deck: deck, installed: installed),
    ),
  );
}

class AppPickerScreen extends StatefulWidget {
  const AppPickerScreen({
    super.key,
    required this.card,
    required this.deck,
    required this.installed,
  });

  final DeckCard card;
  final CardDeck deck;
  final List<LaunchableApp> installed;

  @override
  State<AppPickerScreen> createState() => _AppPickerScreenState();
}

class _AppPickerScreenState extends State<AppPickerScreen> {
  final _chosen = <String>{};
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.installed]..sort(compareByLabel);
    final matches = searchApps(sorted, _query);
    final color = colorOf(widget.card.colorKey);

    return Scaffold(
      backgroundColor: DeckColors.ground,
      // The Scaffold moves the body clear of the keyboard, so there is no
      // inset arithmetic here and nothing is added to or removed from the tree
      // when the keyboard opens.
      resizeToAvoidBottomInset: true,
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
                      child: Icon(
                        Icons.arrow_back_rounded,
                        size: 22,
                        color: DeckColors.text,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(
                      iconOf(widget.card.iconKey),
                      size: 15,
                      color: DeckColors.onCard,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Add to ${widget.card.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: deckText(size: 16, weight: 600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _chosen.isEmpty
                        ? null
                        : () => Navigator.pop(context, _chosen.toList()),
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: DeckColors.onCard,
                      disabledBackgroundColor: DeckColors.surface,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      minimumSize: const Size(0, 40),
                    ),
                    child: Text(
                      _chosen.isEmpty ? 'Add' : 'Add ${_chosen.length}',
                      style: deckText(
                        size: 13,
                        weight: 600,
                        color: _chosen.isEmpty
                            ? DeckColors.textDim
                            : DeckColors.onCard,
                      ),
                    ),
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
                  hintText: 'Search ${widget.installed.length} apps',
                  hintStyle: deckText(size: 13, color: DeckColors.textDim),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 18,
                    color: DeckColors.textDim,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child: matches.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Nothing matches',
                        style: TextStyle(color: DeckColors.textDim),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: matches.length,
                      itemBuilder: (context, index) =>
                          _row(matches[index], color),
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
        : widget.deck.folders.firstWhere((entry) => entry.id == elsewhere).name;

    return ListTile(
      dense: true,
      enabled: !alreadyHere,
      leading: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: chosen ? color : DeckColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: chosen ? color : DeckColors.surfaceEdge),
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
          ? const Text(
              'already on this card',
              style: TextStyle(color: DeckColors.textDim, fontSize: 11),
            )
          : elsewhereName == null
          ? null
          : Text(
              'on $elsewhereName — will move here',
              style: const TextStyle(color: DeckColors.textDim, fontSize: 11),
            ),
      onTap: alreadyHere
          ? null
          : () => setState(() {
              if (!_chosen.remove(app.id)) _chosen.add(app.id);
            }),
    );
  }
}
