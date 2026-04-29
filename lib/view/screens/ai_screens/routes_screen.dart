import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:staysafe/utils/app_colors.dart';

import '../../widgets/text_fields.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  final TextEditingController startController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();

  @override
  void dispose() {
    startController.dispose();
    destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔥 Smart Route Planning Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? const [Color(0xFF1F1B3A), Color(0xFF3A1B2E)]
                    : const [Color(0xFFF3E8FF), Color(0xFFFFE4F3)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColor.appSecondary, width: 2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.zap, color: AppColor.appSecondary, size: 28),
                const SizedBox(width: 10),

                // 💡 Wrap Column in Expanded so NO overflow!
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Smart Route Planning",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        "AI-powered route recommendations based on real-time safety data",
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          CustomTextField(
            hintText: "Starting point",
            icon: LucideIcons.mapPin,
            controller: startController,
          ),

          const SizedBox(height: 12),

          CustomTextField(
            hintText: "Destination",
            icon: LucideIcons.flag,
            controller: destinationController,
          ),
          const SizedBox(height: 12),

          // 🔮 Button (no overflow)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: Container(
              decoration: BoxDecoration(
                color: AppColor.appSecondary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  final start = startController.text.trim();
                  final destination = destinationController.text.trim();
                  if (start.isEmpty || destination.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Please enter both starting point and destination.",
                        ),
                      ),
                    );
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Route preview ready for $start to $destination. Backend route engine comes next.",
                      ),
                    ),
                  );
                },
                icon: const Icon(LucideIcons.sparkles, color: Colors.white),
                label: const Text(
                  "Find Safest Route",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 🟢 Recommended Route Card
          _recommendedRouteCard(),
          const SizedBox(height: 20),

          // 🟠 Alternative Route Card
          _alternativeRouteCard(),
        ],
      ),
    );
  }

  ///----------------Addiitional Widgets Used above----------------///
  // ---------------------------------------
  // RECOMMENDED ROUTE CARD (FIXED)
  // ---------------------------------------
  Widget _recommendedRouteCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F9F1), Color(0xFFDCFCE7)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFF6EE7B7), width: 2),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ICON BOX
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 5),
              ],
            ),
            child: const Icon(LucideIcons.navigation, color: Colors.white),
          ),
          const SizedBox(width: 14),

          // FULL FLEXIBLE AREA
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Recommended Route",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _badge("Safest", Colors.green),
                  ],
                ),

                const SizedBox(height: 4),
                const Text(
                  "Via Bosan Road → Cantt Bypass",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _routeInfo("Distance", "9.5 km"),
                    _routeInfo("Time", "20-22 mins"),
                    _routeInfo("Safety", "89/100", color: Colors.green),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------
  // ALTERNATIVE ROUTE CARD (FIXED)
  // ---------------------------------------
  Widget _alternativeRouteCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade300, width: 2),
      ),
      child: Row(
        children: [
          // ICON
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.orange.shade500,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 5),
              ],
            ),
            child: const Icon(LucideIcons.navigation, color: Colors.white),
          ),
          const SizedBox(width: 14),

          // FLEXIBLE CONTENT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Alternative Route",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _badge("Faster", Colors.orange, outlined: true),
                  ],
                ),

                const SizedBox(height: 4),
                const Text(
                  "Via Nawan Shehr → LMQ Road",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _routeInfo("Distance", "7.1 km"),
                    _routeInfo("Time", "16 mins"),
                    _routeInfo("Safety", "68/100", color: Colors.orange),
                  ],
                ),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: const Text(
                    "⚠ Passes through 1 medium-risk area",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9A3412),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------
  // SMALL COMPONENTS
  // ---------------------------------------
  static Widget _badge(String text, Color color, {bool outlined = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: outlined ? color.withOpacity(0.1) : color,
        borderRadius: BorderRadius.circular(12),
        border: outlined ? Border.all(color: color) : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: outlined ? color : Colors.white,
          fontSize: 11,
        ),
      ),
    );
  }

  static Widget _routeInfo(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
