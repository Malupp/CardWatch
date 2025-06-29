import 'package:flutter/material.dart';
import '../services/scryfall_api.dart';
import '../models/scryfall_set.dart';
import '../models/card_model.dart';
import 'results_page.dart';
import '../widgets/app_drawer.dart';

class DraftPage extends StatefulWidget {
  final Function(int) onNavigate;

  const DraftPage({
    super.key,
    required this.onNavigate,
  });

  @override
  State<DraftPage> createState() => _DraftPageState();
}

class _DraftPageState extends State<DraftPage> {
  List<ScryfallSet> _sets = [];
  ScryfallSet? _selectedSet;
  bool _loadingSets = true;
  bool _loadingCards = false;
  List<CardModel> _cards = [];
  List<CardModel> _filteredCards = [];
  final TextEditingController _searchController = TextEditingController();

  int _currentPage = 0;
  final int _cardsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadSets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSets() async {
    final sets = await ScryfallApi.fetchSets();
    setState(() {
      _sets = sets;
      _loadingSets = false;
    });
  }

  Future<void> _loadCardsForSet(String code) async {
    setState(() {
      _loadingCards = true;
      _cards = [];
    });
    final cards = await ScryfallApi.fetchCardsBySet(code);
    setState(() {
      _cards = cards;
      _filteredCards = cards;
      _loadingCards = false;
      _currentPage = 0;
    });
  }

  void _filterCards(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCards = _cards;
      } else {
        _filteredCards = _cards
            .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
      _currentPage = 0;
    });
  }

  List<CardModel> get _currentPageCards {
    final startIndex = _currentPage * _cardsPerPage;
    final endIndex = (startIndex + _cardsPerPage).clamp(0, _filteredCards.length);
    return _filteredCards.sublist(startIndex, endIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modalità Draft'),
      ),
      drawer: AppDrawer(currentIndex: 3, onSelect: widget.onNavigate),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _loadingSets
                ? const CircularProgressIndicator()
                : DropdownButtonFormField<ScryfallSet>(
                    value: _selectedSet,
                    hint: const Text('Seleziona espansione'),
                    items: _sets
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.name),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedSet = value);
                      if (value != null) _loadCardsForSet(value.code);
                    },
                  ),
            const SizedBox(height: 16),
            if (_selectedSet != null) ...[
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Cerca carta',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onChanged: _filterCards,
              ),
              const SizedBox(height: 16),
            ],
            _loadingCards
                ? const Expanded(child: Center(child: CircularProgressIndicator()))
                : Expanded(
                    child: Column(
                      children: [
                        if (_filteredCards.length > _cardsPerPage)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left),
                                  onPressed: _currentPage > 0
                                      ? () => setState(() => _currentPage--)
                                      : null,
                                ),
                                Text(
                                  "Pagina ${_currentPage + 1} di ${(_filteredCards.length / _cardsPerPage).ceil()}",
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: (_currentPage + 1) * _cardsPerPage < _filteredCards.length
                                      ? () => setState(() => _currentPage++)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _currentPageCards.length,
                            itemBuilder: (context, index) {
                              final card = _currentPageCards[index];
                              return ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                leading: _buildCardImage(card),
                                title: Text(card.name, overflow: TextOverflow.ellipsis),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ResultsPage(query: card.name),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardImage(CardModel card) {
    // Prova prima l'immagine principale
    if (card.imageUrl.isNotEmpty) {
      return Image.network(
        card.imageUrl,
        width: 36,
        height: 54,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => _buildImagePlaceholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 36,
            height: 54,
            color: Colors.grey[100],
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      );
    }
    
    // Se non c'è immagine principale, prova l'immagine normale
    if (card.imageNormalUrl != null && card.imageNormalUrl!.isNotEmpty) {
      return Image.network(
        card.imageNormalUrl!,
        width: 36,
        height: 54,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => _buildImagePlaceholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 36,
            height: 54,
            color: Colors.grey[100],
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      );
    }
    
    // Se non ci sono immagini, mostra placeholder
    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 36,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(
        Icons.image_not_supported,
        size: 20,
        color: Colors.grey,
      ),
    );
  }
}