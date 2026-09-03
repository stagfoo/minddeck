/// Persists the deck across launches.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'card_deck.dart';

class DeckStore {
  static const _key = 'minddeck.cards.v1';

  Future<CardDeck?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return CardDeck.fromJson(jsonDecode(raw));
    } on FormatException {
      // A corrupt value must not brick the home screen; null reseeds.
      return null;
    }
  }

  Future<void> save(CardDeck deck) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(deck.toJson()));
  }
}
