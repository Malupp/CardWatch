import 'package:flutter/material.dart';
import '../services/marketplace_service.dart';
import '../models/card_blueprint.dart';
import '../widgets/card_marketplace_widget.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<CardBlueprint> blueprints = [];
  bool isSearching = false;
  int? selectedBlueprintId;
  String? searchError;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchBlueprints() async {
    if (_searchController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci un termine di ricerca')),
      );
      return;
    }

    try {
      setState(() {
        isSearching = true;
        searchError = null;
        selectedBlueprintId = null; // Reset selezione precedente
      });
      
      final results = await MarketplaceService.getBlueprintList(_searchController.text.trim());
      
      setState(() {
        blueprints = results;
        isSearching = false;
      });

      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nessuna carta trovata')),
        );
      }
    } catch (e) {
      setState(() {
        isSearching = false;
        searchError = e.toString();
        blueprints = []; // Clear previous results on error
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore nella ricerca: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Barra di ricerca
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Cerca carte...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _searchBlueprints(),
                    enabled: !isSearching,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isSearching ? null : _searchBlueprints,
                  child: isSearching 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                ),
              ],
            ),
          ),
          
          // Lista delle carte trovate
          if (blueprints.isNotEmpty) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Seleziona una carta:', 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: blueprints.length,
                itemBuilder: (context, index) {
                  final blueprint = blueprints[index];
                  final isSelected = selectedBlueprintId == blueprint.id;
                  
                  return GestureDetector(
                    onTap: () => setState(() => selectedBlueprintId = blueprint.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 200,
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey,
                          width: isSelected ? 3 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: isSelected ? Colors.blue.withOpacity(0.1) : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            blueprint.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID: ${blueprint.id}', 
                            style: TextStyle(
                              fontSize: 12, 
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          
          // Stato vuoto quando non ci sono risultati
          if (!isSearching && blueprints.isEmpty && _searchController.text.isNotEmpty) 
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Nessuna carta trovata'),
                  ],
                ),
              ),
            ),
          
          // Marketplace della carta selezionata
          if (selectedBlueprintId != null) ...[
            const Divider(),
            Expanded(
              child: CardMarketplaceWidget(blueprintId: selectedBlueprintId!),
            ),
          ],
          
          // Stato iniziale
          if (blueprints.isEmpty && selectedBlueprintId == null && !isSearching)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.store, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Cerca una carta per iniziare'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}