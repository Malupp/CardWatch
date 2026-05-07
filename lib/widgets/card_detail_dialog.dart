import 'package:flutter/material.dart';

import '../models/card_marketplace.dart';
import '../models/scryfall_card_details.dart';
import '../services/unified_card_service.dart';

class CardDetailDialog extends StatelessWidget {
  final CardMarketplace card;

  const CardDetailDialog({super.key, required this.card});

  String get _cardName {
    final storedName = card.propertiesHash['name']?.toString();
    if (storedName != null && storedName.trim().isNotEmpty) {
      return storedName;
    }
    return card.expansion.nameEn;
  }

  String? get _savedImageUrl {
    final normal = card.propertiesHash['imageNormalUrl']?.toString();
    if (normal != null && normal.isNotEmpty) return normal;

    final image = card.propertiesHash['imageUrl']?.toString();
    if (image != null && image.isNotEmpty) return image;

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text(_cardName),
      content: SizedBox(
        width: 560,
        child: FutureBuilder<SavedCardDetails>(
          future: UnifiedCardService.getSavedCardDetails(card),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: 220,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Caricamento dettagli carta...'),
                  ],
                ),
              );
            }

            final details = snapshot.data;
            final scryfall = details?.scryfall;
            final offers = details?.cardTraderOffers ?? [card];

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardImage(imageUrl: scryfall?.imageUrl ?? _savedImageUrl),
                  const SizedBox(height: 16),
                  _ScryfallSection(details: scryfall, fallbackCard: card),
                  const SizedBox(height: 16),
                  _OffersSection(offers: offers),
                  if (snapshot.hasError) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Alcuni dettagli non sono disponibili ora.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CHIUDI'),
        ),
      ],
    );
  }
}

class _CardImage extends StatelessWidget {
  final String? imageUrl;

  const _CardImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                height: 360,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      height: 280,
      width: 200,
      color: Colors.grey[200],
      child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
    );
  }
}

class _ScryfallSection extends StatelessWidget {
  final ScryfallCardDetails? details;
  final CardMarketplace fallbackCard;

  const _ScryfallSection({required this.details, required this.fallbackCard});

  @override
  Widget build(BuildContext context) {
    final data = details;
    final legalFormats =
        data?.legalities.entries
            .where((entry) => entry.value == 'legal')
            .map((entry) => _formatLabel(entry.key))
            .toList() ??
        [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Dettagli Scryfall'),
        _InfoRow('Set', data?.setName ?? fallbackCard.expansion.nameEn),
        _InfoRow('Rarita', data?.displayRarity ?? 'N/A'),
        if (data?.typeLine.isNotEmpty == true) _InfoRow('Tipo', data!.typeLine),
        if (data?.oracleText.isNotEmpty == true) ...[
          const SizedBox(height: 8),
          Text(data!.oracleText, style: Theme.of(context).textTheme.bodyMedium),
        ],
        const SizedBox(height: 12),
        const Text(
          'Prezzi Scryfall',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        if (data == null || data.prices.isEmpty)
          const Text('N/A')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: data.prices.entries
                .map(
                  (entry) => Chip(label: Text('${entry.key}: ${entry.value}')),
                )
                .toList(),
          ),
        const SizedBox(height: 12),
        const Text('Legalita', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        if (legalFormats.isEmpty)
          const Text('Nessun formato legal disponibile')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: legalFormats
                .map(
                  (format) => Chip(
                    label: Text(format),
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  String _formatLabel(String value) {
    final words = value.replaceAll('_', ' ').split(' ');
    return words
        .map(
          (word) =>
              word.isEmpty ? word : word[0].toUpperCase() + word.substring(1),
        )
        .join(' ');
  }
}

class _OffersSection extends StatelessWidget {
  final List<CardMarketplace> offers;

  const _OffersSection({required this.offers});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Offerte CardTrader'),
        const SizedBox(height: 4),
        ...offers.map((offer) => _OfferTile(offer: offer)),
      ],
    );
  }
}

class _OfferTile extends StatelessWidget {
  final CardMarketplace offer;

  const _OfferTile({required this.offer});

  @override
  Widget build(BuildContext context) {
    final details = [
      offer.expansion.nameEn,
      offer.condition,
      if (offer.isFoil) 'Foil',
      if (offer.quantity > 0) 'Qt. ${offer.quantity}',
    ].where((value) => value.isNotEmpty && value != 'N/A').join(' - ');

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.storefront_outlined),
      title: Text(
        offer.user.username.isEmpty ? 'Venditore N/A' : offer.user.username,
      ),
      subtitle: Text(
        details.isEmpty ? 'Dettagli offerta non disponibili' : details,
      ),
      trailing: Text(
        offer.price.formatted.isEmpty ? 'N/A' : offer.price.formatted,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(value.isEmpty ? 'N/A' : value)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}
