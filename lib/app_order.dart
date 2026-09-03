/// Which apps sit on the deck, and in what order.
///
/// The Switch home screen isn't an app drawer — it's a short, hand-arranged
/// row of the things you actually reach for, with everything else behind "All
/// Software". This models that: a pinned, ordered deck plus the remainder.
///
/// Pure Dart; persistence is just a list of ids, so it round-trips through
/// anything.
library;

import 'models.dart';

class Deck {
  const Deck({this.pinnedIds = const []});

  /// Ordered [LaunchableApp.id]s. Ids that no longer resolve to an installed
  /// app are kept rather than dropped, so uninstalling and reinstalling an app
  /// puts it back where it was instead of at the end.
  final List<String> pinnedIds;

  bool contains(String id) => pinnedIds.contains(id);

  /// The pinned apps, in deck order, skipping anything not installed.
  List<LaunchableApp> resolve(List<LaunchableApp> installed) {
    final byId = {for (final app in installed) app.id: app};
    return [
      for (final id in pinnedIds)
        if (byId.containsKey(id)) byId[id]!,
    ];
  }

  /// Everything installed that isn't pinned, alphabetically — the "All
  /// Software" list.
  List<LaunchableApp> rest(List<LaunchableApp> installed) {
    final pinned = pinnedIds.toSet();
    final others = [
      for (final app in installed)
        if (!pinned.contains(app.id)) app,
    ];
    others.sort(compareByLabel);
    return others;
  }

  Deck pin(String id) => contains(id) ? this : Deck(pinnedIds: [...pinnedIds, id]);

  Deck unpin(String id) =>
      Deck(pinnedIds: [...pinnedIds.where((existing) => existing != id)]);

  Deck toggle(String id) => contains(id) ? unpin(id) : pin(id);

  /// Moves the pinned app at [from] to [to], the way a drag-to-reorder lands.
  ///
  /// Indices are into the *pinned* list, and out-of-range values are clamped
  /// rather than thrown: a drag that ends past the end of the row is a normal
  /// gesture, not an error.
  Deck reorder(int from, int to) {
    if (pinnedIds.isEmpty) return this;
    final safeFrom = from.clamp(0, pinnedIds.length - 1);
    final moved = [...pinnedIds];
    final id = moved.removeAt(safeFrom);
    final safeTo = to.clamp(0, moved.length);
    moved.insert(safeTo, id);
    return Deck(pinnedIds: moved);
  }

  /// Seeds a deck for a phone that has never run the launcher, so the first
  /// boot isn't an empty screen. Prefers user-installed apps — the system ones
  /// are mostly OEM plumbing nobody pins on purpose.
  static Deck seedFrom(List<LaunchableApp> installed, {int count = 8}) {
    final sorted = [...installed]..sort((a, b) {
        if (a.isSystem != b.isSystem) return a.isSystem ? 1 : -1;
        return compareByLabel(a, b);
      });
    return Deck(pinnedIds: [for (final app in sorted.take(count)) app.id]);
  }

  List<String> toJson() => pinnedIds;

  static Deck fromJson(Object? json) {
    if (json is! List) return const Deck();
    return Deck(pinnedIds: [for (final entry in json) if (entry is String) entry]);
  }
}

int compareByLabel(LaunchableApp a, LaunchableApp b) {
  final byLabel = a.label.toLowerCase().compareTo(b.label.toLowerCase());
  return byLabel != 0 ? byLabel : a.id.compareTo(b.id);
}

/// Filters the all-apps list by a search string, matching label or package.
List<LaunchableApp> searchApps(List<LaunchableApp> apps, String query) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return apps;
  return [
    for (final app in apps)
      if (app.label.toLowerCase().contains(needle) ||
          app.packageName.toLowerCase().contains(needle))
        app,
  ];
}
