import 'package:flutter/material.dart';

class BubbleNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BubbleNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showLabels = constraints.maxWidth >= 390;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildNavItem(0, Icons.home, 'Home', showLabels),
              _buildNavItem(
                1,
                Icons.collections_bookmark,
                'Collection',
                showLabels,
              ),
              _buildNavItem(2, Icons.favorite, 'Watchlist', showLabels),
              _buildNavItem(3, Icons.shuffle, 'Draft', showLabels),
              _buildNavItem(4, Icons.person, 'Profilo', showLabels),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    bool showLabels,
  ) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: isSelected && showLabels ? 8 : 4,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              if (isSelected && showLabels) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
