import 'dart:async';
import 'package:flutter/material.dart';
import '../pages/results_page.dart';
import '../services/scryfall_api.dart';

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({super.key});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  List<String> _suggestions = [];
  bool _isLoading = false;

  void _onTextChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (value.isNotEmpty) {
        setState(() => _isLoading = true);
        final results = await ScryfallApi.fetchSuggestions(value);
        setState(() {
          _suggestions = results;
          _isLoading = false;
        });
      } else {
        setState(() => _suggestions = []);
      }
    });
  }

  void _selectSuggestion(String suggestion) {
    _controller.text = suggestion;
    setState(() => _suggestions = []);
  }

  void _submitSearch(String query) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultsPage(query: query),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: _onTextChanged,
                onSubmitted: _submitSearch,
                decoration: const InputDecoration(labelText: 'Cerca carte...'),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => _submitSearch(_controller.text),
            ),
          ],
        ),
        if (_isLoading) const CircularProgressIndicator(),
        ..._suggestions.map(
          (s) => ListTile(
            title: Text(s),
            onTap: () => _selectSuggestion(s),
          ),
        ),
      ],
    );
  }
}
