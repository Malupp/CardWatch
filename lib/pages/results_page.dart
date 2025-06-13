import 'package:card_watch/models/card_marketplace.dart';
import 'package:card_watch/models/carousel_item.dart';
import 'package:card_watch/services/marketplace_service.dart';
import 'package:card_watch/widgets/carousel_widget.dart';
import 'package:card_watch/widgets/result_table_widget.dart';
import 'package:flutter/material.dart';
import '../services/scryfall_api.dart';

class ResultsPage extends StatefulWidget {
  final String query;
  const ResultsPage({super.key, required this.query});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  bool _loading = true;
  List<String> _imageUrls = [];
  List<CardMarketplace> _cardsList = [];
  List<CarouselItem> _carouselImages =  [];


  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final results = await ScryfallApi.fetchCardImages(widget.query);
    List<CardMarketplace> cardsList = [];
    List<CarouselItem> carouselImages =  [];
    final blueprintsList = await MarketplaceService.getBlueprintList(
      widget.query,
    );

    for (final blueprint in blueprintsList) {
      List<CardMarketplace> cards = await MarketplaceService.getMarketCard(
        blueprint.id,
      );
      cardsList.addAll(cards); // usa addAll per aggiungere più elementi
    }

    for (final card in cardsList) {
      final alreadyGetted = carouselImages.any((element) => element.description == card.expansion.nameEn);
      if(!alreadyGetted){
      final image = await ScryfallApi.getCardsImageByExpansionCode(widget.query, card.expansion.code);
      carouselImages.add(CarouselItem(url: image, description: card.expansion.nameEn));
      }
    }

    setState(() {
      _imageUrls = results;
      _loading = false;
      _cardsList = cardsList;
      _carouselImages = carouselImages;
    });
  }

  List<Map<String, String>> _cardsListToTableData(List<CardMarketplace> cards) {
    return cards
        .map(
          (card) => {
            'Rivenditore': card.user.username,
            'Prezzo': card.price.formatted,
            'Espansione': card.expansion.nameEn,
            'Condizione': card.condition,
          },
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Risultati: ${widget.query}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _imageUrls.isEmpty
              ? const Center(child: Text('Nessuna carta trovata'))
              : Column(
                  children: [
                    CarouselWidget(items: _carouselImages),
                    Expanded(
                      child: ResultTableWidget(
                        columns: [
                          'Rivenditore',
                          'Prezzo',
                          'Espansione',
                          'Condizione',
                        ],
                        data: _cardsListToTableData(_cardsList),
                      ),
                    ),
                  ],
                ),
    );
  }
}
