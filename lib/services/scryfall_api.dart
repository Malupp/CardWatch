import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/card_model.dart';
import 'marketplace_service.dart';

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
        final card = CardModel.fromScryfallJson(cardJson);
        
        // Prova a ottenere dati aggiuntivi dal marketplace
        try {
          final marketplaceData = await _getMarketplaceDataForCard(card.name);
          if (marketplaceData.isNotEmpty) {
            cards.add(card.mergeWithMarketplaceData(marketplaceData.first));
          } else {
            cards.add(card);
          }
        } catch (e) {
          // Se il marketplace fallisce, usa solo i dati di Scryfall
          cards.add(card);
        }
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
      final cards = <CardModel>[];
      
      for (final cardJson in data) {
        final card = CardModel.fromScryfallJson(cardJson);
        
        // Prova a ottenere dati aggiuntivi dal marketplace
        try {
          final marketplaceData = await _getMarketplaceDataForCard(card.name);
          if (marketplaceData.isNotEmpty) {
            cards.add(card.mergeWithMarketplaceData(marketplaceData.first));
          } else {
            cards.add(card);
          }
        } catch (e) {
          // Se il marketplace fallisce, usa solo i dati di Scryfall
          cards.add(card);
        }
      }
      
      return cards;
    } else {
      return [];
    }
  }

  // Metodo helper per ottenere dati dal marketplace per una carta specifica
  static Future<List<Map<String, dynamic>>> _getMarketplaceDataForCard(String cardName) async {
    try {
      // Prima ottieni i blueprint per la carta
      final blueprints = await MarketplaceService.getBlueprintList(cardName);
      
      if (blueprints.isNotEmpty) {
        // Prendi il primo blueprint e ottieni i dati del marketplace
        final marketplaceCards = await MarketplaceService.getMarketCard(blueprints.first.id);
        
        // Converti i dati del marketplace in formato Map
        return marketplaceCards.map((card) => {
          'name': cardName, // Usa il nome originale
          'image_url': blueprints.first.imageUrl ?? '',
          'set_name': card.expansion.nameEn,
          'price': card.price.formatted,
          'is_foil': card.isFoil,
          'condition': card.condition,
          'seller_name': card.user.username,
          'quantity': card.quantity,
          'is_graded': false, // Non disponibile nel modello attuale
          'artist': '', // Non disponibile nel modello attuale
        }).toList();
      }
    } catch (e) {
      print('Errore nel recupero dati marketplace per $cardName: $e');
    }
    
    return [];
  }
}
