import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../services/unified_card_service.dart';
import 'custom_card_widget.dart';

class RandomCardsWidget extends StatefulWidget {
  const RandomCardsWidget({super.key});

  @override
  State<RandomCardsWidget> createState() => RandomCardsWidgetState();
}

class RandomCardsWidgetState extends State<RandomCardsWidget> 
    with AutomaticKeepAliveClientMixin {
  List<CardModel> _cards = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true; // Mantiene il widget in memoria

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() => _isLoading = true);
    
    final cards = await UnifiedCardService.getUnifiedCards(count: 5);
    
    // Controllo se il widget è ancora montato prima di chiamare setState
    if (mounted) {
      setState(() {
        _cards = cards;
        _isLoading = false;
      });
    }
  }

  // Metodo pubblico per ricaricare le carte
  Future<void> refreshCards() async {
    await _loadCards();
  }

  // Getter per lo stato di caricamento
  bool get isLoading => _isLoading;

  @override
  void dispose() {
    // Cleanup quando il widget viene distrutto
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Richiesto per AutomaticKeepAliveClientMixin
    
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Caricamento carte...'),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _cards.length,
      itemBuilder: (context, index) {
        return CustomCardWidget(card: _cards[index]);
      },
    );
  }
}
