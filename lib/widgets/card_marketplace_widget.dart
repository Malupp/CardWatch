import 'package:flutter/material.dart';
import '../services/marketplace_service.dart';
import '../models/card_marketplace.dart';
import '../models/card_model.dart';
import '../widgets/custom_card_widget.dart';

class CardMarketplaceWidget extends StatefulWidget {
  final int blueprintId;

  const CardMarketplaceWidget({
    super.key,
    required this.blueprintId,
  });

  @override
  State<CardMarketplaceWidget> createState() => _CardMarketplaceWidgetState();
}

class _CardMarketplaceWidgetState extends State<CardMarketplaceWidget> {
  List<CardMarketplace> cards = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadMarketCards();
  }

  Future<void> _loadMarketCards() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final loadedCards = await MarketplaceService.getMarketCard(widget.blueprintId);
      
      setState(() {
        cards = loadedCards;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  // Equivalente della tua funzione statusDefinition
  String statusDefinition(String condition) {
    switch (condition.toLowerCase()) {
      case 'nm':
      case 'near_mint':
        return 'Quasi Perfetto';
      case 'ex':
      case 'excellent':
        return 'Eccellente';
      case 'gd':
      case 'good':
        return 'Buono';
      case 'lp':
      case 'light_played':
        return 'Leggermente Giocato';
      case 'mp':
      case 'moderately_played':
        return 'Moderatamente Giocato';
      case 'hp':
      case 'heavily_played':
        return 'Molto Giocato';
      case 'dm':
      case 'damaged':
        return 'Danneggiato';
      default:
        return condition;
    }
  }

  // Funzione per convertire CardMarketplace in CardModel
  CardModel convertToCardModel(CardMarketplace marketplaceCard) {
    return CardModel(
      name: marketplaceCard.expansion.nameEn, // O usa il nome della carta se disponibile
      imageUrl: marketplaceCard.propertiesHash['image_url']?.toString() ?? 
                'https://via.placeholder.com/300x400?text=No+Image', // URL placeholder se non disponibile
      expansion: marketplaceCard.expansion.nameEn,
      price: marketplaceCard.price.formatted,
      condition: statusDefinition(marketplaceCard.condition),
      isFoil: marketplaceCard.isFoil,
      quantity: marketplaceCard.quantity,
      graded: marketplaceCard.propertiesHash['graded'] == true || 
              marketplaceCard.propertiesHash['graded'] == 'true',
      username: marketplaceCard.user.username,
      artist: marketplaceCard.propertiesHash['artist']?.toString() ?? 'Unknown Artist',
      // Aggiungi altri campi se necessario
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text('Errore: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMarketCards,
              child: const Text('Riprova'),
            ),
          ],
        ),
      );
    }

    if (cards.isEmpty) {
      return const Center(
        child: Text('Nessuna carta trovata nel marketplace'),
      );
    }

    return ListView.builder(
      itemCount: cards.length,
      padding: const EdgeInsets.all(8.0),
      itemBuilder: (context, index) {
        final marketplaceCard = cards[index];
        final cardModel = convertToCardModel(marketplaceCard);
        
        return CustomCardWidget(card: cardModel);
      },
    );
  }
}