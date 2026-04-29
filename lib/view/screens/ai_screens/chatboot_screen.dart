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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            /// Messages
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 10),
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  return _messageBubble(context, controller.messages[index]);
                },
              ),
            ),

            /// Quick actions
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _quickAction(context, "Report Incident", controller),
                  _quickAction(context, "Find safe route", controller),
                  _quickAction(context, "Help", controller),
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
                        hintStyle: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: AppColor.appSecondary),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: colorScheme.outline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: colorScheme.primary),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerLowest,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
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

  Widget _messageBubble(BuildContext context, ChatMessage msg) {
    final isUser = msg.sender == 'user';
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUser
                  ? AppColor.appSecondary.withValues(alpha: 0.3)
                  : AppColor.appPrimary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 0),
                bottomRight: Radius.circular(isUser ? 0 : 16),
              ),
            ),
            child: Text(
              msg.text,
              style: TextStyle(color: colorScheme.onSurface),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Text(
              msg.time,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  //----------buttons like report incident while click on these button a sudden response will generate
  Widget _quickAction(
    BuildContext context,
    String label,
    ChatController controller,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => controller.sendMessage(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColor.appSecondary.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
