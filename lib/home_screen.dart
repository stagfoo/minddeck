import 'dart:async';

import 'package:flutter/material.dart';

import 'card_deck.dart';
import 'card_editor_sheet.dart';
import 'deck_card_view.dart';
import 'deck_store.dart';
import 'folder_screen.dart';
import 'launcher_bridge.dart';
import 'models.dart';
import 'side_rail.dart';
import 'stack_layout.dart';
import 'status_strip.dart';
import 'theme.dart';

/// The home screen: a vertical stack of coloured cards with a pull knob down
/// the right edge, the last card being everything installed.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _store = DeckStore();

  List<LaunchableApp> _installed = const [];
  CardDeck _deck = CardDeck.normalised(const []);
  ScreenMetrics? _metrics;
  int _focused = 0;
  bool _loading = true;
  bool _isDefault = true;
  StreamSubscription<String>? _packageSub;

  @override
  void initState() {
    super.initState();
    _load();
    _packageSub =
        LauncherBridge.instance.packageChanges.listen((_) => _refreshApps());
    LauncherBridge.instance.onHomePressed(() {
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      setState(() => _focused = 0);
    });
  }

  @override
  void dispose() {
    _packageSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final apps = await LauncherBridge.instance.listApps();
    final metrics = await LauncherBridge.instance.screenMetrics();
    final isDefault = await LauncherBridge.instance.isDefaultLauncher();
    var deck = await _store.load();

    // First run: a stack with nothing but "all apps" looks broken, and naming
    // a few starter cards is a better first impression than an empty screen.
    if (deck == null || deck.folders.isEmpty) {
      deck = CardDeck.seed();
      await _store.save(deck);
    }

    if (!mounted) return;
    setState(() {
      _installed = apps;
      _metrics = metrics;
      _deck = deck!;
      _isDefault = isDefault;
      _loading = false;
    });
  }

  Future<void> _refreshApps() async {
    final apps = await LauncherBridge.instance.listApps();
    if (!mounted) return;
    setState(() => _installed = apps);
  }

  Future<void> _update(CardDeck deck) async {
    setState(() {
      _deck = deck;
      _focused = _focused.clamp(0, deck.length - 1);
    });
    await _store.save(deck);
  }

  @override
  Widget build(BuildContext context) {
    // Back must not leave the home screen — there is nothing behind it, and
    // letting the activity finish makes the system restart it.
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: DeckColors.ground,
        body: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF4F00)),
                )
              : Column(
                  children: [
                    StatusStrip(
                      onSettings: LauncherBridge.instance.openSettings,
                      onAdd: _addCard,
                      onLongPressClock: _showMetrics,
                    ),
                    if (!_isDefault) _defaultLauncherBanner(),
                    Expanded(child: _stack()),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _defaultLauncherBanner() {
    return Material(
      color: const Color(0xFFFF4F00).withValues(alpha: 0.16),
      child: InkWell(
        onTap: LauncherBridge.instance.openHomeSettings,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Row(
            children: [
              Icon(Icons.home_outlined, size: 15, color: Color(0xFFFF7A3C)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Not the home app yet — tap to set MindDeck as default',
                  style: TextStyle(fontSize: 11, color: DeckColors.text),
                ),
              ),
              Icon(Icons.chevron_right, size: 15, color: Color(0xFFFF7A3C)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stack() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(DeckMetrics.gutter, 6, 4, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final spec = solveStack(
                  height: constraints.maxHeight,
                  cardCount: _deck.length,
                  focusedIndex: _focused,
                );
                return GestureDetector(
                  // Swiping the stack itself moves focus too — the knob is the
                  // deliberate affordance, not the only one.
                  onVerticalDragEnd: (details) {
                    final velocity = details.primaryVelocity ?? 0;
                    if (velocity < -200) {
                      _moveFocus(1);
                    } else if (velocity > 200) {
                      _moveFocus(-1);
                    }
                  },
                  child: Stack(
                    children: [
                      for (var i = 0; i < _deck.length; i++)
                        AnimatedPositioned(
                          key: ValueKey(_deck[i].id),
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          left: 0,
                          right: 0,
                          top: spec.topOf(i),
                          height: spec.heightOf(i),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: DeckCardView(
                              card: _deck[i],
                              height: spec.heightOf(i) - 4,
                              focused: i == spec.focusedIndex,
                              appCount: _deck[i].isAllApps
                                  ? _installed.length
                                  : _deck[i].resolve(_installed).length,
                              onTap: () => i == _focused
                                  ? _openCard(_deck[i])
                                  : setState(() => _focused = i),
                              onLongPress: () => _editCard(_deck[i]),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          SideRail(
            cardCount: _deck.length,
            focusedIndex: _focused,
            onFocusChanged: (index) => setState(() => _focused = index),
          ),
        ],
      ),
    );
  }

  void _moveFocus(int delta) {
    setState(() => _focused = (_focused + delta).clamp(0, _deck.length - 1));
  }

  Future<void> _openCard(DeckCard card) async {
    final chosen = await Navigator.of(context).push<LaunchableApp>(
      MaterialPageRoute(
        builder: (context) => FolderScreen(
          card: card,
          deck: _deck,
          installed: _installed,
          onDeckChanged: _update,
        ),
      ),
    );
    if (chosen != null) {
      await LauncherBridge.instance.launch(chosen.packageName);
    }
  }

  Future<void> _editCard(DeckCard card) async {
    if (card.isAllApps) return;
    final edited = await showCardEditor(context, card);
    if (edited == null) return;
    await _update(_deck.updateCard(card.id, (_) => edited));
  }

  Future<void> _addCard() async {
    final deck = _deck.addCard('new card');
    await _update(deck);
    final added = deck.folders.last;
    setState(() => _focused = deck.indexOfId(added.id));
    await _editCard(added);
  }

  void _showMetrics() {
    final metrics = _metrics;
    if (metrics == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: DeckColors.surface,
        content: Text('$metrics',
            style: const TextStyle(color: DeckColors.text, fontSize: 12)),
      ),
    );
  }
}
