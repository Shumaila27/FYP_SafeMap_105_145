// lib/view/screens/ai_screens/chatboot_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Controller/chat_controller.dart';
import '../../../Models/chat_message_model.dart';
import '../../../utils/app_colors.dart';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve:    Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl        = context.watch<ChatController>();
    final colorScheme = Theme.of(context).colorScheme;

    // Auto scroll when messages update
    if (ctrl.messages.isNotEmpty) _scrollToBottom();

    // ── Loading state while init runs ──────────────────
    if (ctrl.isInitializing) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [

            // ── Daily limit warning ────────────────────
            if (ctrl.isAtLimit)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: 8, horizontal: 16),
                color: Colors.orange.shade100,
                child: Text(
                  '⚠️ Daily limit reached '
                      '(${ctrl.dailyLimit} messages). '
                      'Resets tomorrow.',
                  style: TextStyle(
                    color:      Colors.orange.shade800,
                    fontSize:   12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // ── Messages list ──────────────────────────
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.only(
                    top: 10, bottom: 4),
                itemCount: ctrl.messages.length +
                    (ctrl.isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  // Show typing indicator as last item
                  if (ctrl.isLoading &&
                      index == ctrl.messages.length) {
                    return _typingIndicator(context);
                  }
                  return _messageBubble(
                      context, ctrl.messages[index]);
                },
              ),
            ),

            // ── Quick action chips ─────────────────────
            if (!ctrl.isAtLimit)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _quickAction(
                          context, '🆘 I feel unsafe', ctrl),
                      const SizedBox(width: 8),
                      _quickAction(
                          context, 'Report Incident', ctrl),
                      const SizedBox(width: 8),
                      _quickAction(
                          context, 'Find safe route', ctrl),
                      const SizedBox(width: 8),
                      _quickAction(context, 'Help', ctrl),
                    ],
                  ),
                ),
              ),

            // ── Input row ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  12, 4, 12, 12),
              child: Row(
                children: [

                  // New Chat button (Fix #4)
                  IconButton(
                    icon: Icon(
                      Icons.add_comment_outlined,
                      color: AppColor.appSecondary,
                    ),
                    tooltip: 'New Chat',
                    onPressed: ctrl.isLoading
                        ? null
                        : () => ctrl.startNewChat(),
                  ),

                  // Text input
                  Expanded(
                    child: TextField(
                      controller: ctrl.messageController,
                      enabled:    !ctrl.isAtLimit,
                      maxLines:   null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: ctrl.isLoading
                          ? null
                          : ctrl.sendMessage,
                      decoration: InputDecoration(
                        hintText: ctrl.isAtLimit
                            ? 'Daily limit reached...'
                            : 'Type your message...',
                        hintStyle: TextStyle(
                            color: colorScheme.onSurfaceVariant),
                        border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(30),
                          borderSide: BorderSide(
                              color: AppColor.appSecondary),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(30),
                          borderSide: BorderSide(
                              color: colorScheme.outline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(30),
                          borderSide: BorderSide(
                              color: colorScheme.primary),
                        ),
                        filled:    true,
                        fillColor:
                        colorScheme.surfaceContainerLowest,
                        contentPadding:
                        const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Send button
                  GestureDetector(
                    onTap: ctrl.isLoading || ctrl.isAtLimit
                        ? null
                        : () => ctrl.sendMessage(
                        ctrl.messageController.text),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                        ctrl.isLoading || ctrl.isAtLimit
                            ? Colors.grey.shade400
                            : AppColor.appSecondary,
                        shape: BoxShape.circle,
                      ),
                      child: ctrl.isLoading
                          ? const SizedBox(
                        width:  20,
                        height: 20,
                        child:
                        CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(
                        Icons.send,
                        color: Colors.white,
                      ),
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

  // ── Message bubble ───────────────────────────────────────

  Widget _messageBubble(BuildContext context, ChatMessage msg) {
    final isUser      = msg.sender == 'user';
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment:
      isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(
                vertical: 4, horizontal: 12),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            constraints: BoxConstraints(
              maxWidth:
              MediaQuery.of(context).size.width * 0.78,
            ),
            decoration: BoxDecoration(
              color: isUser
                  ? AppColor.appSecondary
                  .withValues(alpha: 0.25)
                  : AppColor.appPrimary
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.only(
                topLeft:  const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft:
                Radius.circular(isUser ? 16 : 4),
                bottomRight:
                Radius.circular(isUser ? 4 : 16),
              ),
              border: Border.all(
                color: isUser
                    ? AppColor.appSecondary
                    .withValues(alpha: 0.3)
                    : AppColor.appPrimary
                    .withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              msg.text,
              style: TextStyle(
                  color:    colorScheme.onSurface,
                  fontSize: 14),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 2),
            child: Text(
              msg.time,
              style: TextStyle(
                fontSize: 10,
                color:    colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Typing indicator ─────────────────────────────────────

  Widget _typingIndicator(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(
            vertical: 4, horizontal: 12),
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColor.appPrimary.withValues(alpha: 0.15),
          borderRadius: const BorderRadius.only(
            topLeft:     Radius.circular(16),
            topRight:    Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft:  Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            3,
                (i) => _AnimatedDot(delay: i * 200),
          ),
        ),
      ),
    );
  }

  // ── Quick action chip ────────────────────────────────────

  Widget _quickAction(
      BuildContext context,
      String label,
      ChatController ctrl,
      ) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: ctrl.isLoading
          ? null
          : () => ctrl.sendMessage(label),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColor.appSecondary
              .withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColor.appSecondary
                .withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:      colorScheme.onSurface,
            fontWeight: FontWeight.w500,
            fontSize:   12,
          ),
        ),
      ),
    );
  }
}

// ── Animated typing dot ──────────────────────────────────────

class _AnimatedDot extends StatefulWidget {
  final int delay;
  const _AnimatedDot({required this.delay});

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {

  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(
      Duration(milliseconds: widget.delay),
          () { if (mounted) _ctrl.repeat(reverse: true); },
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 8, height: 8,
        decoration: BoxDecoration(
          color: AppColor.appSecondary.withValues(
              alpha: 0.4 + (_anim.value * 0.6)),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}