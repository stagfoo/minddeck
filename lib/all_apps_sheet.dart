import 'package:flutter/material.dart';

import 'app_order.dart';
import 'app_tile.dart';
import 'launcher_bridge.dart';
import 'models.dart';
import 'theme.dart';

/// The Switch's "All Software" screen: everything installed, searchable, with
/// a tap to launch and a long-press to pin onto the deck.
Future<void> showAllAppsSheet(
  BuildContext context, {
  required List<LaunchableApp> installed,
  required Deck deck,
  required ValueChanged<Deck> onDeckChanged,
  bool startSearching = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: DeckColors.ground,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _AllAppsSheet(
      installed: installed,
      deck: deck,
      onDeckChanged: onDeckChanged,
      startSearching: startSearching,
    ),
  );
}

class _AllAppsSheet extends StatefulWidget {
  const _AllAppsSheet({
    required this.installed,
    required this.deck,
    required this.onDeckChanged,
    required this.startSearching,
  });

  final List<LaunchableApp> installed;
  final Deck deck;
  final ValueChanged<Deck> onDeckChanged;
  final bool startSearching;

  @override
  State<_AllAppsSheet> createState() => _AllAppsSheetState();
}

class _AllAppsSheetState extends State<_AllAppsSheet> {
  late Deck _deck = widget.deck;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.installed]..sort(compareByLabel);
    final matches = searchApps(sorted, _query);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    autofocus: widget.startSearching,
                    style: const TextStyle(color: DeckColors.text, fontSize: 14),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: DeckColors.card,
                      hintText: 'Search ${widget.installed.length} apps',
                      hintStyle:
                          const TextStyle(color: DeckColors.textDim, fontSize: 13),
                      prefixIcon:
                          const Icon(Icons.search, size: 18, color: DeckColors.textDim),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: DeckColors.textDim),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tap to open · hold to pin or unpin from the deck',
                style: TextStyle(fontSize: 11, color: DeckColors.textDim),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: matches.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('Nothing matches',
                          style: TextStyle(color: DeckColors.textDim)),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 96,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final app = matches[index];
                      return AppTile(
                        app: app,
                        size: 56,
                        selected: _deck.contains(app.id),
                        onTap: () {
                          Navigator.pop(context);
                          LauncherBridge.instance.launch(app.packageName);
                        },
                        onLongPress: () {
                          final updated = _deck.toggle(app.id);
                          setState(() => _deck = updated);
                          widget.onDeckChanged(updated);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
