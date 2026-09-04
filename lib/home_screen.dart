import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'card_deck.dart';
import 'app_menu_sheet.dart';
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

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  final _store = DeckStore();

  List<LaunchableApp> _installed = const [];
  CardDeck _deck = CardDeck.normalised(const []);
  ScreenMetrics? _metrics;
  int _focused = 0;
  final _scroll = ScrollController();
  StackSpec? _lastSpec;

  bool _arranging = false;
  String? _draggingId;
  double? _dragTop;
  late final AnimationController _wiggle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
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
    _scroll.dispose();
    _wiggle.dispose();
    super.dispose();
  }

  void _startArranging() {
    setState(() => _arranging = true);
    _wiggle.repeat(reverse: true);
  }

  void _stopArranging() {
    _wiggle.stop();
    setState(() {
      _arranging = false;
      _draggingId = null;
      _dragTop = null;
    });
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
                      onLongPressSettings: _showMetrics,
                    ),
                    if (_arranging)
                      _arrangeBar()
                    else if (!_isDefault)
                      _defaultLauncherBanner(),
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
              builder: (context, constraints) => _arranging
                  ? _arrangeStack(constraints)
                  : _restingStack(constraints),
            ),
          ),
          // One input mode at a time: while arranging, the knob would compete
          // with the reorder drag for the same vertical gesture, so it goes.
          if (!_arranging)
            SideRail(
              cardCount: _deck.length,
              focusedIndex: _focused,
              onFocusChanged: _focus,
            )
          else
            const SizedBox(width: DeckMetrics.railWidth),
        ],
      ),
    );
  }

  Widget _restingStack(BoxConstraints constraints) {
    final spec = solveStack(
      height: constraints.maxHeight,
      cardCount: _deck.length,
      focusedIndex: _focused,
    );
    // Kept so the knob can scroll a long deck to the card it just selected; a
    // plain field, not setState, since this is build.
    _lastSpec = spec;

    final stack = SizedBox(
      height: spec.totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Back to front: the last card — always all apps — is painted first
          // and stays behind everything.
          for (final i in spec.paintOrder)
            AnimatedPositioned(
              key: ValueKey(_deck[i].id),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              left: 0,
              right: 0,
              top: spec.topOf(i),
              height: spec.heightOf(i),
              child: DeckCardView(
                card: _deck[i],
                height: spec.heightOf(i),
                focused: i == spec.focusedIndex,
                apps: _deck[i].resolve(_installed),
                totalInstalled: _installed.length,
                onTap: () => i == _focused
                    ? _openCard(_deck[i])
                    : setState(() => _focused = i),
                onLongPress: _startArranging,
                onAppTap: (app) =>
                    LauncherBridge.instance.launch(app.packageName),
                onAppLongPress: (app) => _showAppMenu(_deck[i], app),
              ),
            ),
        ],
      ),
    );

    return ClipRect(
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity < -200) {
            _moveFocus(1);
          } else if (velocity > 200) {
            _moveFocus(-1);
          }
        },
        child: spec.overflows
            ? SingleChildScrollView(
                controller: _scroll,
                physics: const ClampingScrollPhysics(),
                child: stack,
              )
            : stack,
      ),
    );
  }

  /// Arrange mode: uniform rows you drag to reorder.
  ///
  /// Nothing else here listens for a vertical drag — not the focus swipe, not
  /// the knob, not a scroll view — so the reorder gesture is unambiguous.
  Widget _arrangeStack(BoxConstraints constraints) {
    final spec = solveArrangeStack(
      height: constraints.maxHeight,
      cardCount: _deck.length,
    );

    return ClipRect(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final i in spec.paintOrder) _arrangeCard(spec, i),
        ],
      ),
    );
  }

  Widget _arrangeCard(ArrangeSpec spec, int i) {
    final card = _deck[i];
    final dragging = card.id == _draggingId;
    // The dragged card follows the finger rather than snapping between slots,
    // so it stays under the thumb while the others animate around it.
    final top = dragging && _dragTop != null ? _dragTop! : spec.topOf(i);

    Widget view = AnimatedBuilder(
      animation: _wiggle,
      builder: (context, child) => DeckCardView(
        card: card,
        height: spec.heightOf(i),
        focused: false,
        apps: const [],
        totalInstalled: _installed.length,
        arranging: true,
        lifted: dragging,
        // Alternate the phase so the deck doesn't pulse in unison.
        wigglePhase: (i.isEven ? 1 : -1) * 0.005 * (_wiggle.value * 2 - 1),
        onTap: () => _editCard(card),
        onAppTap: (_) {},
      ),
    );

    if (card.isAllApps) {
      // All apps is pinned to the back of the deck; there is nowhere for it to
      // go, so it is dimmed and left undraggable.
      view = Opacity(opacity: 0.55, child: view);
    } else {
      // The recogniser lives on the card, not on the stack, so the hit test
      // answers "which card am I dragging" and no coordinate has to be mapped
      // back to one.
      view = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (_) => _beginDrag(spec, card),
        onVerticalDragUpdate: (details) => _dragBy(spec, card, details.delta.dy),
        onVerticalDragEnd: (_) => _endDrag(),
        onVerticalDragCancel: _endDrag,
        child: view,
      );
    }

    // The dragged card must not animate — it is already following the finger.
    return dragging
        ? Positioned(
            key: ValueKey(card.id),
            left: 0,
            right: 0,
            top: top,
            height: spec.heightOf(i),
            child: view,
          )
        : AnimatedPositioned(
            key: ValueKey(card.id),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            left: 0,
            right: 0,
            top: top,
            height: spec.heightOf(i),
            child: view,
          );
  }

  void _beginDrag(ArrangeSpec spec, DeckCard card) {
    HapticFeedback.selectionClick();
    setState(() {
      _draggingId = card.id;
      _dragTop = spec.topOf(_deck.indexOfId(card.id));
    });
  }

  void _dragBy(ArrangeSpec spec, DeckCard card, double delta) {
    final index = _deck.indexOfId(card.id);
    if (index < 0) return;
    final next = (_dragTop ?? spec.topOf(index)) + delta;
    setState(() => _dragTop = next);

    // Reorder live as the finger crosses a row, so the deck shows where the
    // card will land rather than only revealing it on release. The probe is the
    // middle of the card's own strip, which is the part the eye tracks.
    final over = spec.indexForY(next + spec.cardHeight - spec.peek / 2);
    final folders = _deck.folders;
    final from = folders.indexWhere((entry) => entry.id == card.id);
    // Clamped to the folders: all apps owns the back of the deck and nothing
    // may be dragged past it.
    final target = over.clamp(0, folders.length - 1);
    if (from >= 0 && target != from) {
      HapticFeedback.selectionClick();
      _update(_deck.reorder(from, target));
    }
  }

  void _endDrag() {
    if (_draggingId == null) return;
    setState(() {
      _draggingId = null;
      _dragTop = null;
    });
  }

  Widget _arrangeBar() {
    return Material(
      color: DeckColors.surface,
      child: InkWell(
        onTap: _stopArranging,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            children: [
              Icon(Icons.drag_indicator_rounded, size: 15, color: DeckColors.textDim),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Drag to reorder · tap a card to edit it',
                  style: TextStyle(fontSize: 11, color: DeckColors.textDim),
                ),
              ),
              Text('Done',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: DeckColors.text)),
            ],
          ),
        ),
      ),
    );
  }

  /// Moves focus and, when the deck is long enough to scroll, brings the newly
  /// focused card into view — otherwise the knob can select a card that is off
  /// the bottom of the stack.
  void _focus(int index) {
    setState(() => _focused = index);
    if (!_scroll.hasClients) return;
    final spec = _lastSpec;
    if (spec == null || !spec.overflows) return;
    final target = (spec.revealTopOf(index) - spec.peek)
        .clamp(0.0, _scroll.position.maxScrollExtent);
    _scroll.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
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

  /// Filing an app straight from the card it is sitting on, so the common case
  /// never needs the all-apps screen.
  Future<void> _showAppMenu(DeckCard from, LaunchableApp app) async {
    final choice = await showAppMenuSheet(
      context,
      app: app,
      deck: _deck,
      from: from,
    );
    switch (choice) {
      case null:
        return;
      case UnfileApp():
        await _update(_deck.unassign(app.id));
      case ShowAppInfo():
        await LauncherBridge.instance.openAppInfo(app.packageName);
      case FileUnder(:final cardId):
        await _update(_deck.assign(app.id, cardId));
    }
  }

  Future<void> _editCard(DeckCard card) async {
    if (card.isAllApps) return;
    final position = _deck.folders.indexWhere((entry) => entry.id == card.id);
    if (position < 0) return;

    final result = await showCardEditor(
      context,
      card,
      position: position,
      folderCount: _deck.folders.length,
    );
    if (result == null) return;

    if (result.deleted) {
      await _deleteCard(card);
      return;
    }

    var deck = _deck.updateCard(card.id, (_) => result.card);
    if (result.position != position) {
      deck = deck.reorder(position, result.position);
    }
    await _update(deck);
    // Follow the card if it moved, so the deck doesn't appear to jump to a
    // different card under the knob.
    final moved = deck.indexOfId(card.id);
    if (moved >= 0) setState(() => _focused = moved);
  }

  Future<void> _addCard() async {
    final deck = _deck.addCard('new card');
    await _update(deck);
    final added = deck.folders.last;
    setState(() => _focused = deck.indexOfId(added.id));
    await _editCard(added);
  }

  Future<void> _deleteCard(DeckCard card) async {
    if (card.isAllApps) return;
    await _update(_deck.removeCard(card.id));
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
