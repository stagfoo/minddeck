import 'package:flutter/material.dart';

import 'app_tile.dart';
import 'card_deck.dart';
import 'models.dart';
import 'theme.dart';

/// What's inside a card: a grid of apps on the card's own colour.
///
/// The all-apps card shows everything installed and offers filing an app onto
/// another card; an ordinary card shows what's filed on it.
class FolderScreen extends StatefulWidget {
  const FolderScreen({
    super.key,
    required this.card,
    required this.deck,
    required this.installed,
    required this.onDeckChanged,
  });

  final DeckCard card;
  final CardDeck deck;
  final List<LaunchableApp> installed;
  final ValueChanged<CardDeck> onDeckChanged;

  @override
  State<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  late CardDeck _deck = widget.deck;
  String _query = '';

  DeckCard get _card {
    final index = _deck.indexOfId(widget.card.id);
    return index >= 0 ? _deck[index] : widget.card;
  }

  void _update(CardDeck deck) {
    setState(() => _deck = deck);
    widget.onDeckChanged(deck);
  }

  @override
  Widget build(BuildContext context) {
    final card = _card;
    final color = colorOf(card.colorKey);
    final apps = searchApps(card.resolve(widget.installed), _query);

    return Scaffold(
      backgroundColor: DeckColors.ground,
      body: SafeArea(
        child: Column(
          children: [
            _header(card, color),
            if (card.isAllApps) _search(),
            Expanded(
              child: apps.isEmpty
                  ? _empty(card)
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 92,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.78,
                      ),
                      itemCount: apps.length,
                      itemBuilder: (context, index) => AppTile(
                        app: apps[index],
                        size: 54,
                        accent: color,
                        filed: _deck.cardIdFor(apps[index].id) != null,
                        onTap: () => Navigator.pop(context, apps[index]),
                        onLongPress: () => _showAppMenu(apps[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(DeckCard card, Color color) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(DeckMetrics.cardRadius),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_rounded,
                size: 22, color: DeckColors.onCard),
          ),
          const SizedBox(width: 10),
          Icon(iconOf(card.iconKey), size: 19, color: DeckColors.onCard),
          const Spacer(),
          Text(
            card.name,
            style: const TextStyle(
              color: DeckColors.onCard,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _search() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: TextField(
        style: const TextStyle(color: DeckColors.text, fontSize: 14),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: DeckColors.surface,
          hintText: 'Search ${widget.installed.length} apps',
          hintStyle: const TextStyle(color: DeckColors.textDim, fontSize: 13),
          prefixIcon:
              const Icon(Icons.search, size: 18, color: DeckColors.textDim),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) => setState(() => _query = value),
      ),
    );
  }

  Widget _empty(DeckCard card) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          card.isAllApps
              ? 'Nothing matches'
              : 'Nothing filed here yet.\nOpen all apps and hold an app to file it.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: DeckColors.textDim, fontSize: 13),
        ),
      ),
    );
  }

  Future<void> _showAppMenu(LaunchableApp app) async {
    final card = _card;
    final target = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: DeckColors.strip,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(app.label,
                  style: const TextStyle(color: DeckColors.text)),
              subtitle: Text(
                app.packageName,
                style: const TextStyle(color: DeckColors.textDim, fontSize: 11),
              ),
            ),
            const Divider(height: 1, color: DeckColors.surfaceEdge),
            if (!card.isAllApps)
              ListTile(
                leading: const Icon(Icons.remove_circle_outline,
                    color: DeckColors.textDim),
                title: Text('Remove from ${card.name}',
                    style: const TextStyle(color: DeckColors.text)),
                onTap: () => Navigator.pop(context, '__remove__'),
              ),
            for (final option in _deck.folders)
              if (option.id != card.id || card.isAllApps)
                ListTile(
                  leading: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: colorOf(option.colorKey),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(iconOf(option.iconKey),
                        size: 13, color: DeckColors.onCard),
                  ),
                  title: Text('File under ${option.name}',
                      style: const TextStyle(color: DeckColors.text)),
                  trailing: _deck.cardIdFor(app.id) == option.id
                      ? const Icon(Icons.check, size: 16, color: DeckColors.textDim)
                      : null,
                  onTap: () => Navigator.pop(context, option.id),
                ),
          ],
        ),
      ),
    );

    if (target == null) return;
    _update(target == '__remove__'
        ? _deck.unassign(app.id)
        : _deck.assign(app.id, target));
  }
}
