import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/card_model.dart';
import '../models/scryfall_set.dart';
import '../models/scryfall_card_details.dart';
import 'marketplace_service.dart';

class ScryfallApi {
  static Map<String, String> get headers => {
    'User-Agent': 'CardWatch/${dotenv.env['VERSION'] ?? '1.0'}',
    'Accept': 'application/json;q=0.9,*/*;q=0.8',
  };

  static String get _baseUrl {
    final configured =
        dotenv.env['BASE_SCRYFALL_API'] ?? 'https://api.scryfall.com';
    return configured.replaceFirst(RegExp(r'/+$'), '');
  }

  static Uri _uri(String path, [Map<String, String>? queryParameters]) {
    final uri = Uri.parse('$_baseUrl$path');
    return queryParameters == null
        ? uri
        : uri.replace(queryParameters: queryParameters);
  }

  static Future<List<String>> fetchSuggestions(String query) async {
    final url = _uri('/cards/autocomplete', {'q': query});
    final res = await http.get(url, headers: headers);

    if (res.statusCode == 200) {
      final jsonBody = json.decode(res.body);
      return (jsonBody['data'] as List<dynamic>).cast<String>();
    } else {
      return [];
    }
  }

  static Future<bool> checkReachable() async {
    try {
      final res = await http
          .get(_uri('/cards/named', {'exact': 'Black Lotus'}), headers: headers)
          .timeout(const Duration(seconds: 8));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<String> getCardsImageByExpansionCode(
    String cardName,
    String expansionCode,
  ) async {
    final url = _uri('/cards/named', {'exact': cardName, 'set': expansionCode});
    final res = await http.get(url, headers: headers);

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return data['image_uris']?['normal'] ??
          data['image_uris']?['art_crop'] ??
          data['card_faces']?[0]?['image_uris']?['normal'] ??
          data['card_faces']?[0]?['image_uris']?['art_crop'] ??
          '';
    } else {
      return '';
    }
  }

  static Future<List<String>> fetchCardImages(String query) async {
    final url = _uri('/cards/search', {'q': query});
    final res = await http.get(url, headers: headers);

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

  static Future<ScryfallCardDetails?> fetchCardDetails(
    String cardName, {
    String? setCode,
  }) async {
    if (cardName.trim().isEmpty) return null;

    final attempts = <Map<String, String>>[
      if (setCode != null && setCode.trim().isNotEmpty)
        {'exact': cardName, 'set': setCode.toLowerCase()},
      {'exact': cardName},
      {'fuzzy': cardName},
    ];

    for (final query in attempts) {
      final res = await http.get(_uri('/cards/named', query), headers: headers);

      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        return ScryfallCardDetails.fromJson(data);
      }

      if (res.statusCode != 404) {
        throw Exception(
          'Errore nel caricamento dettagli Scryfall: ${res.statusCode} - ${res.body}',
        );
      }
    }

    return null;
  }

  static Future<List<ScryfallSet>> fetchSets() async {
    final url = _uri('/sets');
    final res = await http.get(url, headers: headers);

    if (res.statusCode == 200) {
      final data = json.decode(res.body)['data'] as List<dynamic>;
      return data.map((s) => ScryfallSet.fromJson(s)).toList();
    } else {
      return [];
    }
  }

  static Future<List<CardModel>> fetchCardsBySet(String setCode) async {
    final url = _uri('/cards/search', {'q': 'e:$setCode'});
    final res = await http.get(url, headers: headers);

    if (res.statusCode == 200) {
      final data = json.decode(res.body)['data'] as List<dynamic>;
      final cards = <CardModel>[];

      for (final cardJson in data) {
        try {
          final card = CardModel.fromScryfallJson(cardJson);

          // Se l'immagine è vuota, prova a cercare un'immagine alternativa
          if (card.imageUrl.isEmpty && card.imageNormalUrl == null) {
            final alternativeImage = await _tryGetAlternativeImage(
              card.name,
              setCode,
            );
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
          developer.log('Errore nel parsing della carta: $e');
          // Continua con la prossima carta
        }
      }

      return cards;
    } else {
      return [];
    }
  }

  // Metodo per cercare un'immagine alternativa quando quella principale non è disponibile
  static Future<String> _tryGetAlternativeImage(
    String cardName,
    String setCode,
  ) async {
    try {
      // Prova a cercare l'immagine con una query più specifica
      final url = _uri('/cards/search', {'q': '!"$cardName" e:$setCode'});
      final res = await http.get(url, headers: headers);

      if (res.statusCode == 200) {
        final data = json.decode(res.body)['data'] as List<dynamic>;
        if (data.isNotEmpty) {
          final card = data.first;
          return card['image_uris']?['art_crop'] ??
              card['image_uris']?['normal'] ??
              card['card_faces']?[0]['image_uris']?['art_crop'] ??
              card['card_faces']?[0]['image_uris']?['normal'] ??
              '';
        }
      }
    } catch (e) {
      developer.log(
        'Errore nel recupero immagine alternativa per $cardName: $e',
      );
    }

    return '';
  }

  static Future<List<CardModel>> fetchRandomCards(int count) async {
    final List<CardModel> cards = [];

    for (int i = 0; i < count; i++) {
      final url = _uri('/cards/random');
      final res = await http.get(url, headers: headers);

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
        developer.log('Errore nel fetch della carta random: ${res.statusCode}');
      }
    }

    return cards;
  }

  static Future<List<CardModel>> fetchCards() async {
    final url = _uri('/cards/search', {
      'format': 'json',
      'include_extras': 'false',
      'include_multilingual': 'false',
      'include_variations': 'false',
      'order': 'name',
      'page': '2',
      'q': 'c:white mv=1',
      'unique': 'cards',
    });
    final res = await http.get(url, headers: headers);

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
  static Future<List<Map<String, dynamic>>> _getMarketplaceDataForCard(
    String cardName,
  ) async {
    try {
      // Prima ottieni i blueprint per la carta
      final blueprints = await MarketplaceService.getBlueprintList(cardName);

      if (blueprints.isNotEmpty) {
        // Prendi il primo blueprint e ottieni i dati del marketplace
        final marketplaceCards = await MarketplaceService.getMarketCard(
          blueprints.first.id,
        );

        // Converti i dati del marketplace in formato Map
        return marketplaceCards
            .map(
              (card) => {
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
              },
            )
            .toList();
      }
    } catch (e) {
      developer.log('Errore nel recupero dati marketplace per $cardName: $e');
    }

    return [];
  }
}
