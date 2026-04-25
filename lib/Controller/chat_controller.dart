import 'dart:math';
import 'package:flutter/material.dart';

import '../Models/chat_message_model.dart';

class ChatController extends ChangeNotifier {
  /// Input controller
  final TextEditingController messageController = TextEditingController();

  /// Messages list
  final List<ChatMessage> messages = [
    ChatMessage(
      sender: 'bot',
      text:
      "Hello! I'm your SafeMap AI Assistant 💜 I can help you report incidents quickly and safely. How can I assist you today?",
      time: '07:30 PM',
    ),
  ];

  /// Bot predefined responses
  final Map<String, List<String>> botResponses = {
    "Find safe route": [
      "I can help you find the safest route! 🚗\nSwitch to the 'Safe Routes' tab to see AI-powered recommendations.",
    ],
    "Help": [
      "I can help you:\n• Report incidents\n• Find safer routes\n• Activate Guardian Mode",
    ],
    "Report Incident": [
      "Let's report an incident ⚠️\nWhat type of incident was it?",
    ],
  };

  /// Send message
  void sendMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final now = TimeOfDay.now();
    final time =
        "${now.hourOfPeriod.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.period == DayPeriod.am ? 'AM' : 'PM'}";

    messages.add(
      ChatMessage(sender: 'user', text: trimmed, time: time),
    );
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 500), () {
      messages.add(
        ChatMessage(
          sender: 'bot',
          text: _generateBotResponse(trimmed),
          time: time,
        ),
      );
      notifyListeners();
    });

    messageController.clear();
  }

  /// Bot reply logic
  String _generateBotResponse(String userText) {
    final random = Random();

    if (botResponses.containsKey(userText)) {
      final replies = botResponses[userText]!;
      return replies[random.nextInt(replies.length)];
    }

    final generic = [
      "I'm checking that for you... 🔍",
      "Interesting! Let me gather that info.",
      "Give me a moment...",
    ];

    return generic[random.nextInt(generic.length)];
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }
}
