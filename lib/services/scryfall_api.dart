import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/card_model.dart';
import '../models/scryfall_set.dart';
import 'marketplace_service.dart';

class ScryfallApi {
  static String get _baseUrl => dotenv.env['BASE_SCRYFALL_API'] ?? '';

  static Future<List<String>> fetchSuggestions(String query) async {
    final url = Uri.parse('$_baseUrl/cards/autocomplete?q=$query');
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final jsonBody = json.decode(res.body);
      return (jsonBody['data'] as List<dynamic>).cast<String>();
    } else {
      return [];
    }
  }

  static Future<String> getCardsImageByExpansionCode(
    String cardName,
    String expansionCode,
  ) async {
    final url = Uri.parse(
      '$_baseUrl/cards/named?exact=$cardName&set=$expansionCode',
    );
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return data['image_uris']?['art_crop'];
    } else {
      return '';
    }
  }

  static Future<List<String>> fetchCardImages(String query) async {
    final url = Uri.parse('$_baseUrl/cards/search?q=$query');
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final data = json.decode(res.body)['data'];
      return (data as List)
          .map<String>((card) {
            return card['image_uris']?['normal'] ??
                card['card_faces']?[0]['image_uris']?['normal'];
          })
          .whereType<String>()
          .toList();
    } else {
      return [];
    }
  }

  static Future<List<ScryfallSet>> fetchSets() async {
    final url = Uri.parse('$_baseUrl/sets');
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final data = json.decode(res.body)['data'] as List<dynamic>;
      return data.map((s) => ScryfallSet.fromJson(s)).toList();
    } else {
      return [];
    }
  }

  static Future<List<CardModel>> fetchCardsBySet(String setCode) async {
    final url = Uri.parse('$_baseUrl/cards/search?q=e%3A$setCode');
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final data = json.decode(res.body)['data'] as List<dynamic>;
      final cards = <CardModel>[];
      
      for (final cardJson in data) {
        try {
          final card = CardModel.fromScryfallJson(cardJson);
          
          // Se l'immagine è vuota, prova a cercare un'immagine alternativa
          if (card.imageUrl.isEmpty && card.imageNormalUrl == null) {
            final alternativeImage = await _tryGetAlternativeImage(card.name, setCode);
            if (alternativeImage.isNotEmpty) {
              // Crea una nuova carta con l'immagine alternativa
              final updatedCard = CardModel(
                name: card.name,
                imageUrl: alternativeImage,
                imageNormalUrl: card.imageNormalUrl,
                expansion: card.expansion,
                price: card.price,
                isFoil: card.isFoil,
                condition: card.condition,
                username: card.username,
                quantity: card.quantity,
                graded: card.graded,
                artist: card.artist,
                manaCost: card.manaCost,
                typeLine: card.typeLine,
                oracleText: card.oracleText,
                power: card.power,
                toughness: card.toughness,
              );
              cards.add(updatedCard);
            } else {
              cards.add(card);
            }
          } else {
            cards.add(card);
          }
        } catch (e) {
          print('Errore nel parsing della carta: $e');
          // Continua con la prossima carta
        }
      }
      
      return cards;
    } else {
      return [];
    }
  }

  // Metodo per cercare un'immagine alternativa quando quella principale non è disponibile
  static Future<String> _tryGetAlternativeImage(String cardName, String setCode) async {
    try {
      // Prova a cercare l'immagine con una query più specifica
      final url = Uri.parse('$_baseUrl/cards/search?q=!"$cardName"+e:$setCode');
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = json.decode(res.body)['data'] as List<dynamic>;
        if (data.isNotEmpty) {
          final card = data.first;
          return card['image_uris']?['art_crop'] ?? 
                 card['image_uris']?['normal'] ?? 
                 card['card_faces']?[0]['image_uris']?['art_crop'] ??
                 card['card_faces']?[0]['image_uris']?['normal'] ?? '';
        }
      }
    } catch (e) {
      print('Errore nel recupero immagine alternativa per $cardName: $e');
    }
    
    return '';
  }

  static Future<List<CardModel>> fetchRandomCards(int count) async {
    final List<CardModel> cards = [];

    for (int i = 0; i < count; i++) {
      final url = Uri.parse('$_baseUrl/cards/random');
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
      '$_baseUrl/cards/search?format=json&include_extras=false&include_multilingual=false&include_variations=false&order=name&page=2&q=c%3Awhite+mv%3D1&unique=cards',
    );
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
