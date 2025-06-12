import 'package:flutter/material.dart';
import '../services/scryfall_api.dart';

class RandomCardsWidget extends StatefulWidget {
  const RandomCardsWidget({super.key});

  @override
  State<RandomCardsWidget> createState() => _RandomCardsWidgetState();
}

class _RandomCardsWidgetState extends State<RandomCardsWidget> {
  List<String> _images = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRandomCards();
  }

  Future<void> _loadRandomCards() async {
    final images = await ScryfallApi.fetchRandomCards(5);
    setState(() {
      _images = images;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: ListView.separated(
        scrollDirection: Axis.vertical,
        itemCount: _images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return Image.network(_images[index]);
        },
      ),
    );
  }
}
