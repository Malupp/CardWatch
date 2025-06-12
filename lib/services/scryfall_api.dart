import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/card_model.dart';

class ScryfallApi {
  static Future<List<String>> fetchSuggestions(String query) async {
    final url = Uri.parse('https://api.scryfall.com/cards/autocomplete?q=$query');
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final jsonBody = json.decode(res.body);
      return (jsonBody['data'] as List<dynamic>).cast<String>();
    } else {
      return [];
    }
  }

  static Future<List<String>> fetchCardImages(String query) async {
    final url = Uri.parse('https://api.scryfall.com/cards/search?q=$query');
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final data = json.decode(res.body)['data'];
      return (data as List).map<String>((card) {
        return card['image_uris']?['normal'] ?? card['card_faces']?[0]['image_uris']?['normal'];
      }).whereType<String>().toList();
    } else {
      return [];
    }
  }

  static Future<List<CardModel>> fetchRandomCards(int count) async {
  final List<CardModel> cards = [];

  for (int i = 0; i < count; i++) {
    final url = Uri.parse('https://api.scryfall.com/cards/random');
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final cardJson = json.decode(res.body);
      cards.add(CardModel.fromJson(cardJson));
    } else {
      print('Errore nel fetch della carta random: ${res.statusCode}');
    }
  }

  return cards;
}

  static Future<List<CardModel>> fetchCards() async {
    final url = Uri.parse(
        'https://api.scryfall.com/cards/search?format=json&include_extras=false&include_multilingual=false&include_variations=false&order=name&page=2&q=c%3Awhite+mv%3D1&unique=cards');
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final data = json.decode(res.body)['data'];
      return (data as List).map((card) => CardModel.fromJson(card)).toList();
    } else {
      return [];
    }
  }
}
