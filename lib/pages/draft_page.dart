import 'package:flutter/material.dart';

class DraftPage extends StatelessWidget {
  const DraftPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shuffle, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Draft',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Modalità draft casuale'),
        ],
      ),
    );
  }
} 