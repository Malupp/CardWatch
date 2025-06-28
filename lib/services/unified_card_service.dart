import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/card_model.dart';
import 'scryfall_api.dart';
import 'marketplace_service.dart';

class UnifiedCardService {
  /// Ottiene carte combinate da entrambe le API
  static Future<List<CardModel>> getUnifiedCards({
    required int count,
    String? searchQuery,
  }) async {
    List<CardModel> cards = [];
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      // Ricerca specifica
      cards = await _searchCards(searchQuery);
    } else {
      // Carte random
      cards = await _getRandomCards(count);
    }
    
    return cards;
  }

  /// Ottiene carte random con dati combinati
  static Future<List<CardModel>> _getRandomCards(int count) async {
    final List<CardModel> cards = [];

    for (int i = 0; i < count; i++) {
      try {
        // Prima ottieni i dati base da Scryfall
        final scryfallCard = await _getRandomScryfallCard();
        
        // Poi prova a ottenere dati aggiuntivi dal marketplace
        final enrichedCard = await _enrichCardWithMarketplaceData(scryfallCard);
        
        cards.add(enrichedCard);
      } catch (e) {
        print('Errore nel recupero carta random: $e');
      }
    }

    return cards;
  }

  /// Ottiene una carta random da Scryfall
  static Future<CardModel> _getRandomScryfallCard() async {
    final url = Uri.parse('https://api.scryfall.com/cards/random');
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final cardJson = json.decode(res.body);
      return CardModel.fromScryfallJson(cardJson);
    } else {
      throw Exception('Errore nel fetch della carta random: ${res.statusCode}');
    }
  }

  /// Arricchisce una carta con dati dal marketplace
  static Future<CardModel> _enrichCardWithMarketplaceData(CardModel card) async {
    try {
      // Cerca blueprint nel marketplace
      final blueprints = await MarketplaceService.getBlueprintList(card.name);
      
      if (blueprints.isNotEmpty) {
        // Ottieni dati del marketplace
        final marketplaceCards = await MarketplaceService.getMarketCard(blueprints.first.id);
        
        if (marketplaceCards.isNotEmpty) {
          // Prendi la prima carta disponibile nel marketplace
          final marketplaceCard = marketplaceCards.first;
          
          // Gestione intelligente dei prezzi
          String marketplacePrice = marketplaceCard.price.formatted;
          if (marketplaceCard.isFoil) {
            marketplacePrice += ' (Foil)';
          }
          
          // Combina i dati
          return card.mergeWithMarketplaceData({
            'image_url': blueprints.first.imageUrl ?? card.imageUrl,
            'set_name': marketplaceCard.expansion.nameEn,
            'price': marketplacePrice,
            'is_foil': marketplaceCard.isFoil,
            'condition': marketplaceCard.condition,
            'seller_name': marketplaceCard.user.username,
            'quantity': marketplaceCard.quantity,
            'is_graded': false,
            'artist': card.artist, // Mantieni l'artista da Scryfall
          });
        }
      }
    } catch (e) {
      print('Errore nell\'arricchimento con dati marketplace per ${card.name}: $e');
    }
    
    // Se non ci sono dati del marketplace, ritorna la carta originale
    return card;
  }

  /// Ricerca carte con query specifica
  static Future<List<CardModel>> _searchCards(String query) async {
    try {
      // Prima cerca in Scryfall
      final scryfallCards = await ScryfallApi.fetchCards();
      
      // Filtra per la query
      final filteredCards = scryfallCards
          .where((card) => card.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
      
      // Arricchisci con dati del marketplace
      final enrichedCards = <CardModel>[];
      for (final card in filteredCards) {
        final enrichedCard = await _enrichCardWithMarketplaceData(card);
        enrichedCards.add(enrichedCard);
      }
      
      return enrichedCards;
    } catch (e) {
      print('Errore nella ricerca carte: $e');
      return [];
    }
  }
} 