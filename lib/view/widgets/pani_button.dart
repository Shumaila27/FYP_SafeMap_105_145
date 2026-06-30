import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Controller/map_controller.dart';
import 'buttons.dart';

class PanicButton extends StatefulWidget {
  const PanicButton({super.key});

  @override
  State<PanicButton> createState() => _PanicButtonState();
}

class _PanicButtonState extends State<PanicButton>
    with SingleTickerProviderStateMixin {
  bool showConfirm = false;
  bool showResolveConfirm = false;

  // Animation for pulsing effect
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      lowerBound: 0.8,
      upperBound: 1.2,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void handlePanicClick(MapController mapCtrl) {
    if (mapCtrl.isPanicActive) {
      setState(() => showResolveConfirm = true);
    } else {
      setState(() => showConfirm = true);
    }
  }

  void confirmPanic(MapController mapCtrl) {
    setState(() => showConfirm = false);
    mapCtrl.triggerPanicMode();
  }

  void confirmResolve(MapController mapCtrl) {
    setState(() => showResolveConfirm = false);
    mapCtrl.resolvePanicMode();
  }

  @override
  Widget build(BuildContext context) {
    final mapCtrl = context.watch<MapController>();
    final isPanicActive = mapCtrl.isPanicActive;

    return Stack(
      children: [
        // 🔴 Red overlay when panic active
        if (isPanicActive)
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, child) {
              return Opacity(
                opacity: 0.15,
                child: Container(
                  color: Colors.red,
                ),
              );
            },
          ),

        // 🔴 Floating Panic Button
        Positioned(
          bottom: 10,
          left: 10,
          child: GestureDetector(
            onTap: () => handlePanicClick(mapCtrl),
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (_, child) {
                return Transform.scale(
                  scale: isPanicActive ? _pulseController.value : 1.0,
                  child: Container(
                    height: 70,
                    width: 70,
                    decoration: BoxDecoration(
                      color: isPanicActive
                          ? Colors.red.shade600
                          : Colors.red.shade500,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.4),
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // 🟡 Confirmation Dialog
        if (showConfirm)
          Center(
            child: Material(
              color: Colors.black54,
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Activate Panic Mode?",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "This will immediately:",
                        style: TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 20),
                      // list items
                      _infoItem(Icons.location_pin, "Send your live location to guardians"),
                      const SizedBox(height: 8),
                      _infoItem(
                        Icons.phone_in_talk,
                        "Alert nearby SafeMap users",
                      ),
                      const SizedBox(height: 8),
                      _infoItem(Icons.mic, "Start recording audio evidence (local)"),

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              text: "Cancel",
                              textColor: Colors.black,
                              buttonColor: Colors.grey.shade300,
                              onPressed: () {
                                setState(() => showConfirm = false);
                              },
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomButton(
                              text: "Activate",
                              textColor: Colors.white,
                              buttonColor: Colors.red,
                              onPressed: () => confirmPanic(mapCtrl),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "For immediate police assistance, call 15",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // 🟢 Resolve Confirmation Dialog
        if (showResolveConfirm)
          Center(
            child: Material(
              color: Colors.black54,
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        "Are you safe now?",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "This will resolve the SOS alert and notify your guardians that you are safe.",
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              text: "Cancel",
                              textColor: Colors.black,
                              buttonColor: Colors.grey.shade300,
                              onPressed: () {
                                setState(() => showResolveConfirm = false);
                              },
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomButton(
                              text: "I am Safe",
                              textColor: Colors.white,
                              buttonColor: Colors.green,
                              onPressed: () => confirmResolve(mapCtrl),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _infoItem(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.red),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }
}
