import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Controller/chat_controller.dart';
import '../../../Models/chat_message_model.dart';
import '../../../utils/app_colors.dart'; // <-- import your custom colors

class ChatBotScreen extends StatelessWidget {
  const ChatBotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ChatController>(context);

    return Scaffold(
      backgroundColor: AppColor.appBackground, // custom background
      body: SafeArea(
        child: Column(
          children: [
            /// Messages
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 10),
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  return _messageBubble(controller.messages[index]);
                },
              ),
            ),

            /// Quick actions
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _quickAction("Report Incident", controller),
                  _quickAction("Find safe route", controller),
                  _quickAction("Help", controller),
                ],
              ),
            ),

            /// Input field
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.messageController,
                      onSubmitted: controller.sendMessage,
                      decoration: InputDecoration(
                        hintText: "Type your message...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: AppColor.appSecondary),
                        ),
                        contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => controller.sendMessage(
                      controller.messageController.text,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColor.appSecondary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageBubble(ChatMessage msg) {
    final isUser = msg.sender == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
        isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUser
                  ? AppColor.appSecondary.withOpacity(0.3) // user bubble
                  : AppColor.appPrimary.withOpacity(0.3), // bot bubble
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 0),
                bottomRight: Radius.circular(isUser ? 0 : 16),
              ),
            ),
            child: Text(
              msg.text,
              style: const TextStyle(color: Colors.black),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Text(
              msg.time,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }


  //----------buttons like report incident while click on these button a sudden response will generate
  Widget _quickAction(String label, ChatController controller) {
    return GestureDetector(
      onTap: () => controller.sendMessage(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColor.appSecondary.withOpacity(0.3),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: AppColor.appText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
