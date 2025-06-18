import 'package:flutter/material.dart';

class WatchlistPage extends StatefulWidget {
  const WatchlistPage({super.key});

  @override
  State<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage> {
  final List<String> _watchlist = [
    'Black Lotus',
    'Mox Pearl',
    'Time Walk',
    'Ancestral Recall'
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: const Text('Watchlist'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
            ),
          ],
        ),
        Expanded(
          child: _buildWatchlist(),
        ),
      ],
    );
  }

  Widget _buildWatchlist() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _watchlist.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const Icon(Icons.favorite, color: Colors.red),
            title: Text(_watchlist[index]),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => _removeFromWatchlist(index),
            ),
            onTap: () => _showCardDetails(_watchlist[index]),
          ),
        );
      },
    );
  }

  void _removeFromWatchlist(int index) {
    setState(() {
      _watchlist.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rimosso dalla Watchlist')),
    );
  }

  void _showCardDetails(String cardName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(cardName),
        content: const Text('Dettagli della carta...'),
        actions: [
          TextButton(
            child: const Text('CHIUDI'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtra Watchlist'),
        content: const Text('Filtri verranno implementati qui...'),
        actions: [
          TextButton(
            child: const Text('APPLICA'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}