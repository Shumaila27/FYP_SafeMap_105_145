import 'package:flutter/material.dart';
//import 'package:flutter_screenutil/flutter_screenutil.dart';
//import '../../utils/app_colors.dart';
import '../../utils/text_style.dart';
//import '../widgets/buttons.dart'; // ✅ For your customizable button
//import '../widgets/header.dart';
//import '../widgets/text_fields.dart'; // ✅ Import your CustomTextField

class SafeSpotHomeScreen extends StatefulWidget {
  const SafeSpotHomeScreen({super.key});

  @override
  State<SafeSpotHomeScreen> createState() => _SafeSpotHomeScreenState();
}

class _SafeSpotHomeScreenState extends State<SafeSpotHomeScreen> {
  double _mapHeightFactor = 0.55;
  bool _isMinimized = false;

  @override
  Widget build(BuildContext context) {
    final Color neonGreen = const Color(0xFF80FFBF);

    return Scaffold(
      backgroundColor: const Color(0xFF001A0F),
      body: Stack(
        children: [
          // 🔹 Top section: Logo + Map
          Column(
            children: [
              const SizedBox(height: 45),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: neonGreen, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: neonGreen.withOpacity(0.6),
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset("assets/logo.png", fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "SafeSpot",
                    style: AppTextStyle.bold(color: neonGreen).copyWith(
                      fontSize: 28,
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(color: neonGreen.withOpacity(0.8), blurRadius: 25)
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 🔹 Animated Map Section
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                height: MediaQuery.of(context).size.height * _mapHeightFactor,
                margin: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: neonGreen.withOpacity(0.3),
                      blurRadius: 25,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Image.asset(
                    "assets/mock_map.jpeg",
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
            ],
          ),

          // 🔹 Safety Score Panel
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            bottom: _isMinimized
                ? MediaQuery.of(context).size.height * -0.12
                : 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height *
                (_isMinimized ? 0.22 : 0.45),
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta! > 10) {
                  setState(() => _isMinimized = true);
                } else if (details.primaryDelta! < -10) {
                  setState(() => _isMinimized = false);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: const Color(0xFF002A1C),
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(25)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.45),
                      offset: const Offset(0, -2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Main content (only visible when expanded)
                    if (!_isMinimized)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          children: [
                            Center(
                              child: Container(
                                width: 50,
                                height: 6,
                                margin: const EdgeInsets.only(bottom: 15),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            Text(
                              "Safety Score",
                              textAlign: TextAlign.center,
                              style: AppTextStyle.regular(
                                  color: Colors.white70),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "8.4 / 10",
                              textAlign: TextAlign.center,
                              style: AppTextStyle.medium(color: neonGreen)
                                  .copyWith(
                                fontSize: 42,
                                shadows: [
                                  Shadow(
                                      color: neonGreen.withOpacity(0.9),
                                      blurRadius: 25),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 8),
                                overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 20),
                                thumbColor: neonGreen,
                                activeTrackColor: neonGreen,
                                inactiveTrackColor:
                                neonGreen.withOpacity(0.3),
                              ),
                              child: Slider(
                                value: 8.4,
                                min: 0,
                                max: 10,
                                divisions: 10,
                                onChanged: (_) {},
                              ),
                            ),
                            const SizedBox(height: 25),

                            // Quick actions (replaced icons with defaults)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _glowActionButton(Icons.report_problem,
                                    "Report", Colors.redAccent),
                                _glowActionButton(Icons.notifications_active,
                                    "Panic", Colors.orangeAccent),
                                _glowActionButton(Icons.directions_walk,
                                    "Safe Walk", neonGreen),
                              ],
                            ),
                            const SizedBox(height: 30),
                            Text(
                              "Area Insights",
                              style: AppTextStyle.medium(
                                  color: Colors.white),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Recent incidents: Theft and harassment near downtown.\n"
                                  "Hotspots: Saddar, Clifton.\n"
                                  "Tip: Use Safe Walk and avoid dimly lit streets.",
                              style: AppTextStyle.light(
                                  color: Colors.white70)
                                  .copyWith(height: 1.4),
                            ),
                          ],
                        ),
                      ),

                    // 🔹 Visible bar when minimized
                    if (_isMinimized)
                      Align(
                        alignment: Alignment.topCenter,
                        child: GestureDetector(
                          onTap: () => setState(() => _isMinimized = false),
                          child: Container(
                            width: 110,
                            height: 35,
                            margin: const EdgeInsets.only(top: 10),
                            decoration: BoxDecoration(
                              color: neonGreen.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: neonGreen.withOpacity(0.6),
                                  blurRadius: 15,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                "▲ Safety Score",
                                style: AppTextStyle.medium(
                                    color: Colors.white)
                                    .copyWith(fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // 🔹 Minimize/Expand Button
                    Positioned(
                      right: 15,
                      top: 10,
                      child: IconButton(
                        icon: Icon(
                          _isMinimized
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: neonGreen,
                          size: 28,
                        ),
                        onPressed: () =>
                            setState(() => _isMinimized = !_isMinimized),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // 🔹 Bottom Navigation Bar
      bottomNavigationBar: Container(
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF00271A),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              offset: const Offset(0, -2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _hoverNavItem(Icons.home, "Home", neonGreen, true),
            _hoverNavItem(
                Icons.notifications_active, "Alerts", neonGreen, false),
            _hoverNavItem(Icons.warning_amber_rounded, "Panic Button",
                Colors.redAccent, false),
            _hoverNavItem(Icons.person, "Profile", neonGreen, false),
            _hoverNavItem(Icons.settings, "Settings", neonGreen, false),
          ],
        ),
      ),
    );
  }

  // 🔸 Hoverable bottom nav icons
  Widget _hoverNavItem(
      IconData icon, String label, Color glowColor, bool active) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHover = false;
        return MouseRegion(
          onEnter: (_) => setState(() => isHover = true),
          onExit: (_) => setState(() => isHover = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            transform: Matrix4.translationValues(0, isHover ? -4 : 0, 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 26,
                  color: active
                      ? glowColor
                      : isHover
                      ? glowColor.withOpacity(0.9)
                      : Colors.white70,
                  shadows: isHover
                      ? [
                    Shadow(
                        color: glowColor.withOpacity(0.9), blurRadius: 20)
                  ]
                      : [],
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: AppTextStyle.light(
                    color: active
                        ? glowColor
                        : isHover
                        ? glowColor
                        : Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 🔸 Glow action buttons
  Widget _glowActionButton(IconData icon, String label, Color color) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool hover = false;
        return MouseRegion(
          onEnter: (_) => setState(() => hover = true),
          onExit: (_) => setState(() => hover = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            transform: Matrix4.translationValues(0, hover ? -4 : 0, 0),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(hover ? 0.9 : 0.5),
                        blurRadius: hover ? 25 : 12,
                        spreadRadius: hover ? 4 : 2,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFF001F14),
                    child: Icon(icon, color: color, size: 26),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: AppTextStyle.medium(color: color),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
