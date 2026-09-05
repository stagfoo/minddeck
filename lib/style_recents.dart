/// The colours and icons a card has been given that were not on the shelf.
///
/// Picking a custom colour or searching out an icon is deliberate work, and
/// having to redo it for the next card — or after a restart — wastes it. Both
/// are appended to the grids they were reached from, so the second use is a tap.
library;

import 'package:shared_preferences/shared_preferences.dart';

/// Puts [value] at the front of [existing], without duplicates, capped.
///
/// Most recent first, because the thing you just chose is the thing you are
/// most likely to want again — and anything already on the shelf is skipped,
/// so a preset never appears twice.
List<String> appendRecent(
  List<String> existing,
  String value, {
  Iterable<String> alreadyShown = const [],
  int limit = 12,
}) {
  if (value.isEmpty || alreadyShown.contains(value)) return existing;
  return [
    value,
    ...existing.where((entry) => entry != value),
  ].take(limit).toList();
}

class StyleRecents {
  static const _colorsKey = 'rolidecks.recentColors.v1';
  static const _iconsKey = 'rolidecks.recentIcons.v1';

  Future<List<String>> colors() => _load(_colorsKey);

  Future<List<String>> icons() => _load(_iconsKey);

  Future<List<String>> addColor(String key, {Iterable<String> presets = const []}) =>
      _add(_colorsKey, key, presets);

  Future<List<String>> addIcon(String key, {Iterable<String> presets = const []}) =>
      _add(_iconsKey, key, presets);

  Future<List<String>> _load(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key) ?? const [];
  }

  Future<List<String>> _add(
    String key,
    String value,
    Iterable<String> presets,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final updated = appendRecent(
      prefs.getStringList(key) ?? const [],
      value,
      alreadyShown: presets,
    );
    await prefs.setStringList(key, updated);
    return updated;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_colorsKey);
    await prefs.remove(_iconsKey);
  }
}
