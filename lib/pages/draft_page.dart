import 'package:flutter/material.dart';
import '../services/scryfall_api.dart';
import '../models/scryfall_set.dart';
import '../models/card_model.dart';

class DraftPage extends StatefulWidget {
  const DraftPage({super.key});

  @override
  State<DraftPage> createState() => _DraftPageState();
}

class _DraftPageState extends State<DraftPage> {
  int _selectedFormat = 0;
  final List<String> _formats = ['Standard', 'Modern', 'Commander', 'Pauper'];
  List<ScryfallSet> _sets = [];
  ScryfallSet? _selectedSet;
  bool _loadingSets = true;
  bool _loadingCards = false;
  List<CardModel> _cards = [];

  @override
  void initState() {
    super.initState();
    _loadSets();
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
      _loadingCards = false;
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
                _buildFormatSelector(),
                const SizedBox(height: 16),
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
                _loadingCards
                    ? const Expanded(child: Center(child: CircularProgressIndicator()))
                    : Expanded(
                        child: ListView.builder(
                          itemCount: _cards.length,
                          itemBuilder: (context, index) {
                            final card = _cards[index];
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

  Widget _buildFormatSelector() {
    return SizedBox(
      width: 250,
      child: DropdownButtonFormField<int>(
        value: _selectedFormat,
        items: _formats.asMap().entries.map((entry) {
          return DropdownMenuItem<int>(
            value: entry.key,
            child: Text(entry.value),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedFormat = value!;
          });
        },
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ),
      ),
    );
  }

  void _startDraft() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Draft Iniziato!'),
        content: Text('Formato: ${_formats[_selectedFormat]}'),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}