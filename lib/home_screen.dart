import 'dart:async';

import 'package:flutter/material.dart';

import 'all_apps_sheet.dart';
import 'app_order.dart';
import 'app_tile.dart';
import 'deck_store.dart';
import 'grid_layout.dart';
import 'launcher_bridge.dart';
import 'models.dart';
import 'status_strip.dart';
import 'theme.dart';

/// The home screen itself: status strip, the deck of pinned tiles, and the
/// system row along the bottom.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _store = DeckStore();

  List<LaunchableApp> _installed = const [];
  Deck _deck = const Deck();
  ScreenMetrics? _metrics;
  bool _loading = true;
  bool _isDefault = true;
  StreamSubscription<String>? _packageSub;

  @override
  void initState() {
    super.initState();
    _load();
    _packageSub = LauncherBridge.instance.packageChanges.listen((_) => _refreshApps());
    // Pressing HOME while already home closes whatever is open, the way every
    // stock launcher behaves.
    LauncherBridge.instance.onHomePressed(() {
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
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

    // First run on a phone: an empty home screen looks broken, so seed it.
    if (deck.pinnedIds.isEmpty && apps.isNotEmpty) {
      deck = Deck.seedFrom(apps);
      await _store.save(deck);
    }

    if (!mounted) return;
    setState(() {
      _installed = apps;
      _metrics = metrics;
      _deck = deck;
      _isDefault = isDefault;
      _loading = false;
    });
  }

  Future<void> _refreshApps() async {
    final apps = await LauncherBridge.instance.listApps();
    if (!mounted) return;
    setState(() => _installed = apps);
  }

  Future<void> _update(Deck deck) async {
    setState(() => _deck = deck);
    await _store.save(deck);
  }

  @override
  Widget build(BuildContext context) {
    // Back must not leave the home screen — there is nothing behind it, and
    // letting the activity finish makes the system restart it, which reads as
    // a flicker.
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: DeckColors.ground,
        body: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: DeckColors.selection),
                )
              : Column(
                  children: [
                    StatusStrip(
                      onSettings: LauncherBridge.instance.openSettings,
                      onSearch: () => _openAllApps(startSearching: true),
                      onLongPressClock: _showMetrics,
                    ),
                    if (!_isDefault) _defaultLauncherBanner(),
                    Expanded(child: _deckArea()),
                    _systemRow(),
                  ],
                ),
        ),
      ),
    );
  }

  /// Until the phone is actually handed over, say so — a launcher you have to
  /// open from another launcher is a confusing thing to be looking at.
  Widget _defaultLauncherBanner() {
    return Material(
      color: DeckColors.selection.withValues(alpha: 0.14),
      child: InkWell(
        onTap: LauncherBridge.instance.openHomeSettings,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: DeckMetrics.deckPadding, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.home_outlined, size: 16, color: DeckColors.selection),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Not the home app yet — tap to set MindDeck as default',
                  style: TextStyle(fontSize: 12, color: DeckColors.text),
                ),
              ),
              Icon(Icons.chevron_right, size: 16, color: DeckColors.selection),
            ],
          ),
        ),
      ),
    );
  }

  Widget _deckArea() {
    final pinned = _deck.resolve(_installed);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DeckMetrics.deckPadding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Tiles carry a label underneath, so the solver gets the box minus
          // that strip and the grid still fits.
          const labelStrip = 22.0;
          final grid = solveGrid(
            width: constraints.maxWidth,
            height: constraints.maxHeight - labelStrip,
          );

          if (pinned.isEmpty) {
            return Center(
              child: TextButton.icon(
                onPressed: () => _openAllApps(),
                icon: const Icon(Icons.add, color: DeckColors.selection),
                label: const Text(
                  'Pick some apps for the deck',
                  style: TextStyle(color: DeckColors.text),
                ),
              ),
            );
          }

          final visible = pinned.take(grid.capacity).toList();
          return Center(
            child: SizedBox(
              width: grid.contentWidth,
              child: Wrap(
                spacing: grid.gap,
                runSpacing: grid.gap,
                alignment: WrapAlignment.center,
                children: [
                  for (final app in visible)
                    AppTile(
                      key: ValueKey(app.id),
                      app: app,
                      size: grid.tileSize,
                      onTap: () => LauncherBridge.instance.launch(app.packageName),
                      onLongPress: () => _showTileMenu(app),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _systemRow() {
    return Container(
      height: DeckMetrics.systemRowHeight,
      color: DeckColors.strip,
      padding: const EdgeInsets.symmetric(horizontal: DeckMetrics.deckPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _SystemButton(
            icon: Icons.apps,
            label: 'All apps',
            onTap: () => _openAllApps(),
          ),
          _SystemButton(
            icon: Icons.tune,
            label: 'Arrange',
            onTap: () => _openAllApps(),
          ),
          _SystemButton(
            icon: Icons.settings,
            label: 'Settings',
            onTap: LauncherBridge.instance.openSettings,
          ),
        ],
      ),
    );
  }

  /// Reports what the panel actually measured, so the tuning numbers in
  /// GridStyle can be checked against reality rather than assumed.
  void _showMetrics() {
    final metrics = _metrics;
    if (metrics == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: DeckColors.card,
        content: Text(
          '$metrics',
          style: const TextStyle(color: DeckColors.text, fontSize: 12),
        ),
      ),
    );
  }

  Future<void> _openAllApps({bool startSearching = false}) async {
    await showAllAppsSheet(
      context,
      installed: _installed,
      deck: _deck,
      startSearching: startSearching,
      onDeckChanged: _update,
    );
  }

  Future<void> _showTileMenu(LaunchableApp app) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: DeckColors.strip,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(app.label, style: const TextStyle(color: DeckColors.text)),
              subtitle: Text(
                app.packageName,
                style: const TextStyle(color: DeckColors.textDim, fontSize: 11),
              ),
            ),
            const Divider(height: 1, color: DeckColors.cardEdge),
            ListTile(
              leading: const Icon(Icons.push_pin_outlined, color: DeckColors.textDim),
              title: const Text('Remove from deck',
                  style: TextStyle(color: DeckColors.text)),
              onTap: () => Navigator.pop(context, 'unpin'),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: DeckColors.textDim),
              title: const Text('App info', style: TextStyle(color: DeckColors.text)),
              onTap: () => Navigator.pop(context, 'info'),
            ),
            if (!app.isSystem)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: DeckColors.textDim),
                title:
                    const Text('Uninstall', style: TextStyle(color: DeckColors.text)),
                onTap: () => Navigator.pop(context, 'uninstall'),
              ),
          ],
        ),
      ),
    );

    switch (action) {
      case 'unpin':
        await _update(_deck.unpin(app.id));
      case 'info':
        await LauncherBridge.instance.openAppInfo(app.packageName);
      case 'uninstall':
        await LauncherBridge.instance.requestUninstall(app.packageName);
    }
  }
}

class _SystemButton extends StatelessWidget {
  const _SystemButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: DeckColors.textDim),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 10, color: DeckColors.textDim)),
          ],
        ),
      ),
    );
  }
}
