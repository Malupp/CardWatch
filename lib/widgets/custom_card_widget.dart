import 'package:flutter/material.dart';
import '../models/card_model.dart';

class CustomCardWidget extends StatelessWidget {
  final CardModel card;

  const CustomCardWidget({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(card.imageUrl, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(card.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Espansione: ${card.expansion}'),
                Text('Prezzo: ${card.price}'),
                Text('Condizione: ${card.condition}'),
                Text('Foil: ${card.isFoil ? "Sì" : "No"}'),
                Text('Quantità: ${card.quantity}'),
                Text('Graded: ${card.graded ? "Sì" : "No"}'),
                Text('Venditore: ${card.username}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
