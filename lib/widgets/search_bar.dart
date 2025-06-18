import 'dart:async';
import 'package:flutter/material.dart';
import '../pages/results_page.dart';
import '../services/scryfall_api.dart';

class SearchBarWidget extends StatefulWidget {
  final RouteObserver<ModalRoute<void>> routeObserver;
  
  const SearchBarWidget({
    super.key,
    required this.routeObserver,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> with RouteAware {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  List<String> _suggestions = [];
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    widget.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Quando si torna indietro alla HomePage, resetta lo stato
    _controller.clear();
    setState(() {
      _suggestions = [];
      _isLoading = false;
    });
  }

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
    _submitSearch(suggestion);
  }

  void _submitSearch(String query) {
    if (query.trim().isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResultsPage(query: query.trim()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _controller,
          onChanged: _onTextChanged,
          onSubmitted: _submitSearch,
          decoration: InputDecoration(
            labelText: 'Cerca carte...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    setState(() => _suggestions = []);
                  },
                )
              : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            filled: true,
            fillColor: Theme.of(context).cardColor,
          ),
        ),
        if (_isLoading) 
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: CircularProgressIndicator(),
          ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: _suggestions.map(
                (s) => ListTile(
                  title: Text(s),
                  onTap: () => _selectSuggestion(s),
                ),
              ).toList(),
            ),
          ),
      ],
    );
  }
}
