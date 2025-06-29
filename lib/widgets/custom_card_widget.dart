import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../services/local_storage.dart';
import '../models/card_marketplace.dart';
import '../services/marketplace_service.dart';

class CustomCardWidget extends StatefulWidget {
  final CardModel card;
  final VoidCallback? onTap;
  final bool showActions;

  const CustomCardWidget({
    super.key,
    required this.card,
    this.onTap,
    this.showActions = true,
  });

  @override
  State<CustomCardWidget> createState() => _CustomCardWidgetState();
}

class _CustomCardWidgetState extends State<CustomCardWidget> {
  bool _isImageLoading = true;
  bool _hasImageError = false;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(CustomCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card.imageUrl != widget.card.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    setState(() {
      _isImageLoading = true;
      _hasImageError = false;
    });

    // Prova prima l'immagine principale
    if (widget.card.imageUrl.isNotEmpty) {
      _currentImageUrl = widget.card.imageUrl;
      return;
    }

    // Se non c'è immagine principale, prova l'immagine normale
    if (widget.card.imageNormalUrl != null && widget.card.imageNormalUrl!.isNotEmpty) {
      _currentImageUrl = widget.card.imageNormalUrl;
      return;
    }

    // Se ancora non c'è immagine, prova a cercare nel marketplace
    try {
      final blueprints = await MarketplaceService.getBlueprintList(widget.card.name);
      if (blueprints.isNotEmpty && blueprints.first.imageUrl != null) {
        setState(() {
          _currentImageUrl = blueprints.first.imageUrl;
        });
        return;
      }
    } catch (e) {
      // Ignora errori del marketplace
    }

    // Se tutto fallisce, mostra errore
    setState(() {
      _hasImageError = true;
      _isImageLoading = false;
    });
  }

  Widget _buildImage() {
    if (_currentImageUrl == null || _currentImageUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    return Image.network(
      _currentImageUrl!,
      width: double.infinity,
      height: 200,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          setState(() => _isImageLoading = false);
          return child;
        }
        return _buildLoadingPlaceholder();
      },
      errorBuilder: (context, error, stackTrace) {
        setState(() {
          _hasImageError = true;
          _isImageLoading = false;
        });
        return _buildPlaceholder();
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: 200,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _hasImageError ? Icons.broken_image : Icons.image_not_supported,
            size: 50,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            _hasImageError ? 'Immagine non disponibile' : 'Nessuna immagine',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      width: double.infinity,
      height: 200,
      color: Colors.grey[100],
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  CardMarketplace _toMarketplace(CardModel card) {
    return CardMarketplace(
      user: CardUser(username: card.username),
      expansion: CardExpansion(nameEn: card.expansion, code: '', id: 0),
      price: CardPrice(formatted: card.price),
      propertiesHash: {
        'name': card.name,
        'condition': card.condition,
        'foil': card.isFoil,
        'signed': false,
        'language': 'N/A',
        'imageUrl': card.imageUrl,
        'imageNormalUrl': card.imageNormalUrl,
      },
      quantity: card.quantity ?? 1,
    );
  }

  void _toggleCollection(CardModel card) {
    final isInCollection = LocalStorage().collection.any((c) => c.expansion.nameEn == card.expansion && c.user.username == card.username);
    if (isInCollection) {
      LocalStorage().removeFromCollection(_toMarketplace(card));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${card.name} rimossa dalla collezione')),
      );
    } else {
      LocalStorage().addToCollection(_toMarketplace(card));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${card.name} aggiunta alla collezione')),
      );
    }
    setState(() {});
  }

  void _toggleWatchlist(CardModel card) {
    final isInWatchlist = LocalStorage().watchlist.any((c) => c.expansion.nameEn == card.expansion && c.user.username == card.username);
    if (isInWatchlist) {
      LocalStorage().removeFromWatchlist(_toMarketplace(card));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${card.name} rimossa dalla watchlist')),
      );
    } else {
      LocalStorage().addToWatchlist(_toMarketplace(card));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${card.name} aggiunta alla watchlist')),
      );
    }
    setState(() {});
  }

  Widget _buildDetailRow(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle ?? const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 10,
          color: Colors.blue[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isInCollection = LocalStorage().collection.any((c) => c.expansion.nameEn == widget.card.expansion && c.user.username == widget.card.username);
    final isInWatchlist = LocalStorage().watchlist.any((c) => c.expansion.nameEn == widget.card.expansion && c.user.username == widget.card.username);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: widget.onTap ?? () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(widget.card.name),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Image.network(
                              _currentImageUrl!,
                              height: 250,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 250,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      child: const Text('CHIUDI'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              );
            },
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: _buildImage(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.card.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.card.artist.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'by ${widget.card.artist}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                _buildDetailRow('Set', widget.card.expansion),
                if (widget.card.price.contains('(Foil:'))
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(
                        'Prezzo Normale',
                        widget.card.price.split('(Foil:')[0].trim(),
                        valueStyle: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      _buildDetailRow(
                        'Prezzo Foil',
                        widget.card.price.split('(Foil:')[1].replaceAll(')', '').trim(),
                        valueStyle: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  )
                else if (widget.card.price.contains('(Foil)'))
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(
                        'Prezzo',
                        widget.card.price.replaceAll(' (Foil)', ''),
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
                    widget.card.price,
                    valueStyle: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                if (widget.card.condition != 'N/A')
                  _buildDetailRow('Condizione', widget.card.condition),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _buildDetailChip('Foil', widget.card.isFoil ? 'Sì' : 'No'),
                    if (widget.card.graded) _buildDetailChip('Graded', 'Sì'),
                    if (widget.card.quantity != null && widget.card.quantity! > 1)
                      _buildDetailChip('Quantità', widget.card.quantity.toString()),
                  ],
                ),
                if (widget.showActions) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _toggleCollection(widget.card),
                          icon: Icon(
                            Icons.collections_bookmark_outlined,
                            color: isInCollection ? Colors.green : null,
                          ),
                          label: Text(
                            isInCollection ? 'Rimuovi' : 'Collezione',
                            style: TextStyle(
                              color: isInCollection ? Colors.green : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _toggleWatchlist(widget.card),
                          icon: Icon(
                            isInWatchlist ? Icons.favorite : Icons.favorite_border,
                            color: isInWatchlist ? Colors.red : null,
                          ),
                          label: Text(
                            isInWatchlist ? 'Rimuovi' : 'Watchlist',
                            style: TextStyle(
                              color: isInWatchlist ? Colors.red : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}