import 'package:flutter/material.dart';

class RefreshButton extends StatelessWidget {
  final VoidCallback onRefresh;
  final bool isLoading;

  const RefreshButton({
    super.key,
    required this.onRefresh,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onRefresh,
        icon: isLoading 
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.refresh),
        label: Text(
          isLoading ? 'Caricamento...' : 'Nuove Carte',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 3,
        ),
      ),
    );
  }
} 