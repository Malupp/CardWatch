import 'package:flutter/material.dart';
import '../services/scryfall_api.dart';

class ResultsPage extends StatefulWidget {
  final String query;
  const ResultsPage({super.key, required this.query});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  bool _loading = true;
  List<String> _imageUrls = [];

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final results = await ScryfallApi.fetchCardImages(widget.query);
    setState(() {
      _imageUrls = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Risultati: ${widget.query}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _imageUrls.isEmpty
              ? const Center(child: Text('Nessuna carta trovata'))
              : ListView.builder(
                  itemCount: _imageUrls.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.network(_imageUrls[index]),
                  ),
                ),
    );
  }
}
