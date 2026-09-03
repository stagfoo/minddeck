/// Persists the deck across launches.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'app_order.dart';

class DeckStore {
  static const _key = 'minddeck.deck.v1';

  Future<Deck> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const Deck();
    try {
      return Deck.fromJson(jsonDecode(raw));
    } on FormatException {
      // A corrupt value must not brick the home screen — an empty deck reseeds
      // itself on the next launch.
      return const Deck();
    }
  }

  Future<void> save(Deck deck) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(deck.toJson()));
  }
}
