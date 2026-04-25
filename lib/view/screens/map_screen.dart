import 'package:flutter/material.dart';
import '../../Models/map_model.dart';
import '../widgets/app_bar.dart';
import '../widgets/pani_button.dart';

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

    return Scaffold(
      appBar: const AppMainBar(showBack: true),
      body: Column(
        children: [
          // 🔍 Search + Location Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    hintText: "Search location or area...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.purple),
                    ),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () => setState(() => searchQuery = ''),
                            icon: const Icon(Icons.close, color: Colors.grey),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),

                // 📍 Current Location Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEDE9FE), Color(0xFFFCE7F3)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Location Text
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Current Location",
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Gulgashat, Multan",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      // Safety Score
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: const [
                          Row(
                            children: [
                              Text(
                                "78",
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              SizedBox(width: 4),
                              Text(
                                "/100",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                          Text(
                            "Safety Score",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
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
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFF1F5F9), Color(0xFFF8FAFC)],
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
                          color: Colors.purple,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(50),
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
                              ).withOpacity(0.7),
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
                      color: Colors.red.withOpacity(0.2),
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
                      color: Colors.orange.withOpacity(0.15),
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Risk Levels",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _legendDot(Colors.red, "High Risk"),
                        _legendDot(Colors.orange, "Medium"),
                        _legendDot(Colors.yellow, "Low Risk"),
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
              child: const Icon(Icons.info),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => _incidentDialog(selectedIncident!),
                );
              },
            )
          : null,
    );
  }

  // Incident Dialog
  Widget _incidentDialog(Incident incident) {
    return AlertDialog(
      title: const Text("Incident Details"),
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
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    incident.type,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Text(
              "Description",
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(incident.description),
            const SizedBox(height: 10),

            Text(
              "Reported",
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(incident.time),
            const SizedBox(height: 15),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                border: Border.all(color: Colors.amber.shade200),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                "⚠️ Exercise caution when traveling through this area",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.amber,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text("Close"),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
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
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
      ..color = Colors.grey.withOpacity(0.1)
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
