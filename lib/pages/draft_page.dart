import 'package:flutter/material.dart';

class DraftPage extends StatefulWidget {
  const DraftPage({super.key});

  @override
  State<DraftPage> createState() => _DraftPageState();
}

class _DraftPageState extends State<DraftPage> {
  int _selectedFormat = 0;
  final List<String> _formats = ['Standard', 'Modern', 'Commander', 'Pauper'];

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
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shuffle, size: 60, color: Colors.blue),
                const SizedBox(height: 20),
                const Text(
                  'Seleziona un formato:',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
                _buildFormatSelector(),
                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: const Text('INIZIA DRAFT'),
                  onPressed: _startDraft,
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