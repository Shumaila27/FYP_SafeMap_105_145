import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:staysafe/utils/app_colors.dart';
import 'package:staysafe/view/screens/ai_screens/ai.dart';
import 'package:staysafe/view/screens/map_screen.dart';
import 'package:staysafe/view/screens/profile.dart';
import 'package:staysafe/view/screens/safe_walk_screens/safewalk.dart';
import '../screens/report_screen/report_screen.dart';

class CustomNav extends StatefulWidget {
  const CustomNav({super.key});

  @override
  State<CustomNav> createState() => _CustomNavState();
}

class _CustomNavState extends State<CustomNav> {
  int pageIndex = 0;

  final pages = [
    MapScreen(),
    const AIRecommendationScreen(),
    const SafeWalkScreen(),
    const ReportScreen(),
    ProfileScreen()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[pageIndex],
      bottomNavigationBar: buildMyNavBar(context),
    );
  }

  Container buildMyNavBar(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: AppColor.appSecondary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(icon: Icons.location_on, label: "Map", index: 0),
          _navItem(icon: Icons.auto_awesome, label: "AI", index: 1),
          _navItem(icon: LucideIcons.footprints, label: "SafeWalk", index: 2),
          _navItem(icon: Icons.report, label: "Report", index: 3),
          _navItem(icon: Icons.person, label: "Profile", index: 4),
        ],
      ),
    );
  }

  Widget _navItem({required IconData icon, required String label, required int index}) {
    bool isSelected = pageIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          pageIndex = index;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 28,
            color: isSelected ? Colors.white : Colors.white70,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
