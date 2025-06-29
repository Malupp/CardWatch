import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  final int currentIndex;
  final Function(int) onSelect;

  const AppDrawer({
    super.key,
    required this.currentIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: const Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'CardWatch',
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
            ),
          ),
          _buildItem(context, Icons.home, 'Home', 0),
          _buildItem(context, Icons.collections, 'Collection', 1),
          _buildItem(context, Icons.favorite, 'Watchlist', 2),
          _buildItem(context, Icons.shuffle, 'Draft', 3),
          _buildItem(context, Icons.person, 'Profilo', 4),
        ],
      ),
    );
  }

  Widget _buildItem(
      BuildContext context, IconData icon, String label, int index) {
    final isSelected = currentIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.blue : null),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.blue : null,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onSelect(index);
      },
    );
  }
}
