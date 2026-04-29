import 'package:flutter/material.dart';
import '../../Models/map_model.dart';
import '../widgets/app_bar.dart';
import '../widgets/pani_button.dart';
import '../../utils/app_colors.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String searchQuery = '';
  Incident? selectedIncident;

  Color getSeverityColor(String severity) {
    switch (severity) {
      case 'high':
        return Colors.red.shade500;
      case 'medium':
        return Colors.orange.shade500;
      case 'low':
        return Colors.yellow.shade500;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const AppMainBar(showBack: true),
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          // 🔍 Search + Location Header
          Container(
            padding: const EdgeInsets.all(16),
            color: colorScheme.surfaceContainerLowest,
            child: Column(
              children: [
                TextField(
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  style: TextStyle(color: AppColor.getTextPrimary(context)),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, color: AppColor.getIconSecondary(context)),
                    hintText: "Search location or area...",
                    hintStyle: TextStyle(color: AppColor.getTextTertiary(context)),
                    filled: true,
                    fillColor: AppColor.getContainerBackground(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColor.getContainerBorder(context)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColor.getContainerBorder(context)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColor.getInteractivePrimary(context)),
                    ),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () => setState(() => searchQuery = ''),
                            icon: Icon(Icons.close, color: AppColor.getIconSecondary(context)),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),

                // 📍 Current Location Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                          : [const Color(0xFFEDE9FE), const Color(0xFFFCE7F3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.teal.shade700 : Colors.purple.shade200,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Location Text
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Current Location",
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? AppColor.teal300 : Colors.purple.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Gulgashat, Multan",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColor.getTextPrimary(context),
                            ),
                          ),
                        ],
                      ),

                      // Safety Score
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                "78",
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColor.teal400 : Colors.green.shade600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "/100",
                                style: TextStyle(
                                  color: AppColor.getTextSecondary(context),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            "Safety Score",
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColor.getTextSecondary(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 🗺️ Main Map Area
          Expanded(
            child: Stack(
              children: [
                // Background gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? const [Color(0xFF0F172A), Color(0xFF111827)]
                          : const [Color(0xFFF1F5F9), Color(0xFFF8FAFC)],
                    ),
                  ),
                ),

                // Grid Lines
                CustomPaint(
                  size: Size(size.width, size.height),
                  painter: GridPainter(),
                ),

                // User Location (purple dot)
                Positioned(
                  left: size.width * 0.5 - 10,
                  top: size.height * 0.25,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColor.teal400,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.teal.withValues(alpha: 0.4),
                              blurRadius: 12,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Incident Markers
                ...mockIncidents.map((incident) {
                  return Positioned(
                    left: size.width * incident.location.dx / 100 - 20,
                    top: size.height * incident.location.dy / 100 - 20,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIncident = incident;
                        });
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: getSeverityColor(
                                incident.severity,
                              ).withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                // Heat Zones
                Positioned(
                  top: size.height * 0.3,
                  right: size.width * 0.2,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                Positioned(
                  bottom: size.height * 0.25,
                  left: size.width * 0.15,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),

                // Legend
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColor.getContainerBackground(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColor.getContainerBorder(context)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Risk Levels",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppColor.getTextPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _legendDot(Colors.red, "High Risk", context),
                        _legendDot(Colors.orange, "Medium", context),
                        _legendDot(Colors.yellow, "Low Risk", context),
                      ],
                    ),
                  ),
                ),

                // 🔴 PANIC BUTTON
                const PanicButton(),
              ],
            ),
          ),
        ],
      ),

      // Incident Popup Dialog Trigger FAB
      floatingActionButton: selectedIncident != null
          ? FloatingActionButton(
              backgroundColor: AppColor.getInteractivePrimary(context),
              child: const Icon(Icons.info, color: Colors.white),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => _incidentDialog(selectedIncident!, context),
                );
              },
            )
          : null,
    );
  }

  // Incident Dialog
  Widget _incidentDialog(Incident incident, BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColor.getContainerBackground(context),
      title: Text(
        "Incident Details",
        style: TextStyle(color: AppColor.getTextPrimary(context)),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Risk Tag + Type
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: incident.severity == 'high'
                        ? Colors.red
                        : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${incident.severity.toUpperCase()} RISK",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColor.getContainerBorder(context)),
                  ),
                  child: Text(
                    incident.type,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColor.getTextPrimary(context),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Text(
              "Description",
              style: TextStyle(
                color: AppColor.getTextSecondary(context),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            Text(
              incident.description,
              style: TextStyle(color: AppColor.getTextPrimary(context)),
            ),
            const SizedBox(height: 10),

            Text(
              "Reported",
              style: TextStyle(
                color: AppColor.getTextSecondary(context),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            Text(
              incident.time,
              style: TextStyle(color: AppColor.getTextPrimary(context)),
            ),
            const SizedBox(height: 15),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                "⚠️ Exercise caution when traveling through this area",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.amber,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text(
            "Close",
            style: TextStyle(color: AppColor.getInteractivePrimary(context)),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColor.getTextSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}

// 🌐 Grid Painter
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const step = 40.0;
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.1)
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
