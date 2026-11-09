import 'package:flutter/material.dart';

/// شريط التنقل السفلي المشترك بين الـ Shells مع دعم الشارات (Badges)
class ModernBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavItem> items;

  const ModernBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          items.length,
          (i) => _NavItem(
            item: items[i],
            isSelected: currentIndex == i,
            primaryColor: primaryColor,
            onTap: () => onTap(i),
          ),
        ),
      ),
    );
  }
}

class BottomNavItem {
  final IconData icon;
  final String label;
  final int badgeCount;

  const BottomNavItem({
    required this.icon,
    required this.label,
    this.badgeCount = 0,
  });
}

class _NavItem extends StatelessWidget {
  final BottomNavItem item;
  final bool isSelected;
  final Color primaryColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.item,
    required this.isSelected,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  item.icon,
                  color: isSelected ? primaryColor : Colors.grey[400],
                  size: 24,
                ),
                if (item.badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade800,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        item.badgeCount > 99 ? '99+' : '${item.badgeCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                item.label,
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
