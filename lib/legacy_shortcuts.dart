/// Shortcuts the system does not remember.
///
/// The older "add to home screen" hands the launcher an intent, a name and a
/// bitmap and then forgets about it — unlike a pinned shortcut, nothing in
/// Android knows it exists. So the launcher keeps them, icon and all.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// One stored shortcut and the icon that came with it.
class StoredShortcut {
  const StoredShortcut({required this.app, this.icon});

  final LaunchableApp app;
  final Uint8List? icon;

  Map<String, dynamic> toJson() => {
        ...app.toJson(),
        if (icon != null) 'icon': base64Encode(icon!),
      };

  static StoredShortcut? fromJson(Object? json) {
    if (json is! Map) return null;
    final map = json.cast<String, dynamic>();
    if (map['intentUri'] is! String) return null;
    final raw = map['icon'];
    Uint8List? icon;
    if (raw is String) {
      try {
        icon = base64Decode(raw);
      } on FormatException {
        icon = null;
      }
    }
    return StoredShortcut(app: LaunchableApp.fromJson(map), icon: icon);
  }
}

class LegacyShortcutStore {
  static const _key = 'rolidecks.legacyShortcuts.v1';

  Future<List<StoredShortcut>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final entry in decoded)
          if (StoredShortcut.fromJson(entry) case final shortcut?) shortcut,
      ];
    } on FormatException {
      // Unreadable is a miss, not a failure: better to lose the shortcuts than
      // to refuse to draw the launcher.
      return const [];
    }
  }

  Future<List<StoredShortcut>> add(StoredShortcut shortcut) async {
    final existing = await load();
    // Adding the same shortcut twice replaces it rather than duplicating —
    // the intent is the identity, so a second one is the same door.
    final updated = [
      ...existing.where((entry) => entry.app.id != shortcut.app.id),
      shortcut,
    ];
    await _save(updated);
    return updated;
  }

  Future<List<StoredShortcut>> remove(String id) async {
    final updated =
        (await load()).where((entry) => entry.app.id != id).toList();
    await _save(updated);
    return updated;
  }

  Future<void> _save(List<StoredShortcut> shortcuts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode([for (final entry in shortcuts) entry.toJson()]),
    );
  }
}
