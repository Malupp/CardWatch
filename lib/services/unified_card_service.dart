import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../models/card_marketplace.dart';
import '../models/card_model.dart';
import '../models/scryfall_card_details.dart';
import 'scryfall_api.dart';
import 'marketplace_service.dart';

class SavedCardDetails {
  final ScryfallCardDetails? scryfall;
  final List<CardMarketplace> cardTraderOffers;

  const SavedCardDetails({
    required this.scryfall,
    required this.cardTraderOffers,
  });
}

class UnifiedCardService {
  static const Duration _requestTimeout = Duration(seconds: 12);

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
        developer.log('Errore nel recupero carta random: $e');
      }
    }

    return cards;
  }

  /// Ottiene una carta random da Scryfall
  static Future<CardModel> _getRandomScryfallCard() async {
    final url = Uri.parse('https://api.scryfall.com/cards/random');

    for (int attempt = 0; attempt < 3; attempt++) {
      final res = await http
          .get(url, headers: ScryfallApi.headers)
          .timeout(_requestTimeout);

      if (res.statusCode == 200) {
        final cardJson = json.decode(res.body);
        return CardModel.fromScryfallJson(cardJson);
      }

      if (res.statusCode == 429 || res.statusCode >= 500) {
        await Future.delayed(Duration(milliseconds: 300 * (attempt + 1)));
        continue;
      }

      throw Exception(
        'Errore nel fetch della carta random: ${res.statusCode} - ${res.body}',
      );
    }

    throw Exception(
      'Errore nel fetch della carta random: troppi tentativi falliti',
    );
  }

  /// Arricchisce una carta con dati dal marketplace
  static Future<CardModel> _enrichCardWithMarketplaceData(
    CardModel card,
  ) async {
    try {
      // Cerca blueprint nel marketplace
      final blueprints = await MarketplaceService.getBlueprintList(card.name);

      if (blueprints.isNotEmpty) {
        // Ottieni dati del marketplace
        final marketplaceCards = await MarketplaceService.getMarketCard(
          blueprints.first.id,
        );

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
      developer.log(
        'Errore nell\'arricchimento con dati marketplace per ${card.name}: $e',
      );
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
          .where(
            (card) => card.name.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();

      // Arricchisci con dati del marketplace
      final enrichedCards = <CardModel>[];
      for (final card in filteredCards) {
        final enrichedCard = await _enrichCardWithMarketplaceData(card);
        enrichedCards.add(enrichedCard);
      }

      return enrichedCards;
    } catch (e) {
      developer.log('Errore nella ricerca carte: $e');
      return [];
    }
  }

  static Future<SavedCardDetails> getSavedCardDetails(
    CardMarketplace card,
  ) async {
    final cardName = _savedCardName(card);

    final scryfallFuture = ScryfallApi.fetchCardDetails(
      cardName,
      setCode: card.expansion.code,
    ).catchError((_) => null);

    final offersFuture = _getSavedCardMarketplaceOffers(
      cardName,
      card,
    ).catchError((_) => <CardMarketplace>[]);

    final results = await Future.wait<dynamic>([scryfallFuture, offersFuture]);

    return SavedCardDetails(
      scryfall: results[0] as ScryfallCardDetails?,
      cardTraderOffers: results[1] as List<CardMarketplace>,
    );
  }

  static String _savedCardName(CardMarketplace card) {
    final storedName = card.propertiesHash['name']?.toString();
    if (storedName != null && storedName.trim().isNotEmpty) {
      return storedName;
    }

    return card.expansion.nameEn;
  }

  static Future<List<CardMarketplace>> _getSavedCardMarketplaceOffers(
    String cardName,
    CardMarketplace savedCard,
  ) async {
    final offers = <CardMarketplace>[];

    final blueprintId = _savedBlueprintId(savedCard);
    if (blueprintId > 0) {
      final directOffers = await MarketplaceService.getMarketCard(blueprintId);
      offers.addAll(
        directOffers.map(
          (offer) => _copyOfferMetadata(offer, savedCard, cardName),
        ),
      );
    }

    if (offers.isEmpty) {
      final blueprints = await MarketplaceService.getBlueprintList(cardName);

      for (final blueprint in blueprints.take(3)) {
        final blueprintOffers = await MarketplaceService.getMarketCard(
          blueprint.id,
        );
        offers.addAll(
          blueprintOffers.map((offer) {
            final props = Map<String, dynamic>.from(offer.propertiesHash);
            props['name'] = blueprint.name;
            props['imageUrl'] ??= blueprint.imageUrl;
            props['imageNormalUrl'] ??= blueprint.imageUrl;

            return CardMarketplace(
              user: offer.user,
              expansion: offer.expansion,
              price: offer.price,
              propertiesHash: props,
              quantity: offer.quantity,
            );
          }),
        );

        if (offers.length >= 8) break;
      }
    }

    if (offers.isEmpty) {
      return [savedCard];
    }

    return offers.take(8).toList();
  }

  static CardMarketplace _copyOfferMetadata(
    CardMarketplace offer,
    CardMarketplace savedCard,
    String cardName,
  ) {
    final props = Map<String, dynamic>.from(offer.propertiesHash);
    props['name'] ??= cardName;
    props['imageUrl'] ??= savedCard.propertiesHash['imageUrl'];
    props['imageNormalUrl'] ??= savedCard.propertiesHash['imageNormalUrl'];

    return CardMarketplace(
      user: offer.user,
      expansion: offer.expansion,
      price: offer.price,
      propertiesHash: props,
      quantity: offer.quantity,
    );
  }

  static int _savedBlueprintId(CardMarketplace savedCard) {
    final rawBlueprintId = savedCard.propertiesHash['blueprintId'];
    if (rawBlueprintId is int) return rawBlueprintId;
    return int.tryParse(rawBlueprintId?.toString() ?? '') ?? 0;
  }
}
