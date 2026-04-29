import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return buildMyNavBar(context);
  }

  Container buildMyNavBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(
            icon: Icons.location_on,
            label: "Map",
            index: 0,
            onPrimary: colorScheme.onPrimary,
          ),
          _navItem(
            icon: Icons.auto_awesome,
            label: "AI",
            index: 1,
            onPrimary: colorScheme.onPrimary,
          ),
          _navItem(
            icon: LucideIcons.footprints,
            label: "SafeWalk",
            index: 2,
            onPrimary: colorScheme.onPrimary,
          ),
          _navItem(
            icon: Icons.report,
            label: "Report",
            index: 3,
            onPrimary: colorScheme.onPrimary,
          ),
          _navItem(
            icon: Icons.person,
            label: "Profile",
            index: 4,
            onPrimary: colorScheme.onPrimary,
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required int index,
    required Color onPrimary,
  }) {
    bool isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () {
        onTap(index);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 28,
            color: isSelected ? onPrimary : onPrimary.withValues(alpha: 0.74),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? onPrimary : onPrimary.withValues(alpha: 0.74),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
