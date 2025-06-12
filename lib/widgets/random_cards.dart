import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../services/scryfall_api.dart';
import 'custom_card_widget.dart';

class RandomCardsWidget extends StatefulWidget {
  const RandomCardsWidget({super.key});

  @override
  State<RandomCardsWidget> createState() => _RandomCardsWidgetState();
}

class _RandomCardsWidgetState extends State<RandomCardsWidget> {
  List<CardModel> _cards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final cards = await ScryfallApi.fetchRandomCards(5);
    setState(() {
      _cards = cards;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
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
