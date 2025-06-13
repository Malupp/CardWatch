import 'package:flutter/material.dart';
import '../models/card_model.dart';

class CustomCardWidget extends StatelessWidget {
  final CardModel card;

  const CustomCardWidget({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Immagine della carta
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              card.imageUrl,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                height: 200,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                ),
              ),
            ),
          ),
          
          // Dettagli della carta
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nome della carta
                Text(
                  card.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                // Autore
                if (card.artist.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'by ${card.artist}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                
                // Espansione
                _buildDetailRow('Set', card.expansion),
                
                // Prezzi (normale e foil)
                if (card.price.contains('(Foil:'))
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(
                        'Prezzo Normale',
                        card.price.split('(Foil:')[0].trim(),
                        valueStyle: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      _buildDetailRow(
                        'Prezzo Foil',
                        card.price.split('(Foil:')[1].replaceAll(')', '').trim(),
                        valueStyle: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  )
                else if (card.price.contains('(Foil)'))
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(
                        'Prezzo',
                        card.price.replaceAll(' (Foil)', ''),
                        valueStyle: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      _buildDetailRow(
                        'Tipo',
                        'Foil',
                        valueStyle: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  )
                else
                  _buildDetailRow(
                    'Prezzo',
                    card.price,
                    valueStyle: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                
                // Condizione (non più sempre Near Mint)
                if (card.condition != 'N/A')
                  _buildDetailRow('Condizione', card.condition),
                
                // Dettagli aggiuntivi
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _buildDetailChip('Foil', card.isFoil ? 'Sì' : 'No'),
                    if (card.graded) _buildDetailChip('Graded', 'Sì'),
                    if (card.quantity != null)
                      _buildDetailChip('Disponibili', '${card.quantity}'),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Venditore
                if (card.username != 'N/A')
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Venduto da ${card.username}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper per creare righe di dettaglio formattate
  Widget _buildDetailRow(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }

  // Helper per creare chip di dettaglio
  Widget _buildDetailChip(String label, String value) {
    return Chip(
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      backgroundColor: Colors.grey[100],
      label: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}