import 'dart:async';
import 'package:flutter/material.dart';
import 'buttons.dart';

class PanicButton extends StatefulWidget {
  const PanicButton({super.key});

  @override
  State<PanicButton> createState() => _PanicButtonState();
}

class _PanicButtonState extends State<PanicButton>
    with SingleTickerProviderStateMixin {
  bool isPanicActive = false;
  bool showConfirm = false;

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

  void activatePanic() {
    setState(() => isPanicActive = true);

    // Auto turn off after 30 seconds
    Timer(const Duration(seconds: 30), () {
      if (mounted) {
        setState(() => isPanicActive = false);
      }
    });
  }

  void handlePanicClick() {
    setState(() => showConfirm = true);
  }

  void confirmPanic() {
    setState(() => showConfirm = false);
    activatePanic();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 🔴 Red overlay when panic active
        if (isPanicActive)
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, child) {
              return Opacity(opacity: 0.2, child: Container(color: Colors.red));
            },
          ),

        // 🔴 Floating Panic Button
        Positioned(
          bottom: 10,
          left: 10,
          child: GestureDetector(
            onTap: handlePanicClick,
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
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
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
                    _infoItem(Icons.location_pin, "Send your live location"),
                    _infoItem(
                      Icons.phone_in_talk,
                      "Alert nearby SafeMap users",
                    ),
                    _infoItem(Icons.mic, "Start recording audio evidence"),

                    const SizedBox(height: 15),

                    // Buttons using YOUR CustomButton
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
                        const SizedBox(width: 10),
                        Expanded(
                          child: CustomButton(
                            text: "Activate",
                            textColor: Colors.white,
                            buttonColor: Colors.red,
                            onPressed: confirmPanic,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    const Text(
                      "For immediate police assistance, call 15",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
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
