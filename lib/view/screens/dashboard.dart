import 'package:flutter/material.dart';
import 'package:staysafe/view/screens/map_screen.dart';
import 'package:staysafe/view/screens/profile.dart';
import 'package:staysafe/view/screens/report_screen/report_screen.dart';
import 'package:staysafe/view/screens/safe_walk_screens/safewalk.dart';
import 'package:staysafe/view/widgets/nav_bar.dart';
import 'ai_screens/ai.dart';

class DashBoardScreen extends StatefulWidget {
  const DashBoardScreen({super.key});

  @override
  State<DashBoardScreen> createState() => _DashBoardScreenState();
}

class _DashBoardScreenState extends State<DashBoardScreen> {
  int currentIndex = 0;

  List screens = [
    const MapScreen(), // index 0
    const AIRecommendationScreen(), // index 1
    const SafeWalkScreen(),
    const ReportScreen(),
    const ProfileScreen(),
  ];

  void onTap(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: CustomNav(),
    );
  }
}
