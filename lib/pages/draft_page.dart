import 'package:flutter/material.dart';
import '../services/scryfall_api.dart';
import '../models/scryfall_set.dart';
import '../models/card_model.dart';
import 'results_page.dart';

class DraftPage extends StatefulWidget {
  const DraftPage({super.key});

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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: const Text('Modalità Draft'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        Expanded(
          child: Padding(
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
                    decoration: const InputDecoration(
                      labelText: 'Cerca carta',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: _filterCards,
                  ),
                  const SizedBox(height: 16),
                ],
                _loadingCards
                    ? const Expanded(child: Center(child: CircularProgressIndicator()))
                    : Expanded(
                        child: ListView.builder(
                          itemCount: _filteredCards.length,
                          itemBuilder: (context, index) {
                            final card = _filteredCards[index];
                            return ListTile(
                              leading: card.imageUrl.isNotEmpty
                                  ? Image.network(
                                      card.imageUrl,
                                      width: 40,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
                                    )
                                  : null,
                              title: Text(card.name),
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
        ),
      ],
    );
  }
}