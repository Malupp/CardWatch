import 'dart:convert';
import 'package:http/http.dart' as http;

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

  static Future<List<String>> fetchRandomCards(int count) async {
  List<String> images = [];

  for (int i = 0; i < count; i++) {
    final url = Uri.parse('https://api.scryfall.com/cards/random');
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final card = json.decode(res.body);
      final image = card['image_uris']?['normal'] ?? card['card_faces']?[0]['image_uris']?['normal'];
      if (image != null) images.add(image);
    }
  }

  return images;
}
}
