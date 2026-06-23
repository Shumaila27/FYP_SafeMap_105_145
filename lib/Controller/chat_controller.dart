// lib/Controller/chat_controller.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../Models/chat_message_model.dart';
import '../services/chat_service.dart';

class ChatController extends ChangeNotifier {

  final _svc = ChatService.instance;

  final List<ChatMessage>     messages          = [];
  final TextEditingController messageController = TextEditingController();

  bool    _isLoading      = false;
  bool    _isInitializing = true;
  String? _sessionId;
  String? _error;
  int     _todayCount     = 0;

  static const int _dailyLimit = 50;

  bool    get isLoading      => _isLoading;
  bool    get isInitializing => _isInitializing;
  String? get error          => _error;
  int     get todayCount     => _todayCount;
  int     get dailyLimit     => _dailyLimit;
  bool    get isAtLimit      => _todayCount >= _dailyLimit;

  // ════════════════════════════════════════════════════════
  //  INIT
  // ════════════════════════════════════════════════════════

  Future<void> init() async {
    _isInitializing = true;
    notifyListeners();

    try {
      _sessionId  = await _svc.loadLatestSessionId();
      _todayCount = await _svc.getTodayMessageCount();

      if (_sessionId != null) {
        final loaded = await _svc.loadMessages(_sessionId!);
        messages.addAll(loaded);
      }

      // Show welcome only if no real history
      if (messages.isEmpty) {
        _addWelcomeMessage();
      }

    } catch (e) {
      debugPrint('[ChatController] init error: $e');
      _addWelcomeMessage();
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  void _addWelcomeMessage() {
    messages.add(ChatMessage.local(
      role: 'assistant',
      text: "Hi! I'm SafeGuard 🛡️\n\n"
          "I'm your personal safety assistant for SafeMap. "
          "I can help with safety tips, emergency guidance, "
          "legal rights, and how to use SafeMap features.\n\n"
          "How can I help you stay safe today?",
    ));
  }

  // ════════════════════════════════════════════════════════
  //  SEND MESSAGE
  // ════════════════════════════════════════════════════════

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isLoading) return;

    if (isAtLimit) {
      _showRateLimitMessage();
      return;
    }

    messageController.clear();

    // 1. Add user message to UI immediately
    messages.add(ChatMessage.local(role: 'user', text: trimmed));
    _isLoading = true;
    _error     = null;
    notifyListeners();

    try {
      // 2. Create session on first real message
      _sessionId ??= await _svc.createSession(trimmed);

      // ✅ Fix — only send REAL DB messages as history
      // Exclude: local welcome message, the message we just added
      final history = messages
          .where((m) => !m.isLocal)  // only messages saved in DB
          .toList();

      // 3. Send to Gemini via edge function
      final reply = await _svc.sendMessage(
        sessionId:   _sessionId!,
        userMessage: trimmed,
        history:     history,
      );

      // 4. Add AI reply to UI
      messages.add(ChatMessage.local(role: 'assistant', text: reply));
      _todayCount++;

    } on SocketException {
      _handleError('No internet connection. Please check your network.');
    } on TimeoutException {
      _handleError('Request timed out. Please try again.');
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      debugPrint('[ChatController] sendMessage error: $e');
      if (msg.contains('Daily limit')) {
        _showRateLimitMessage();
      } else {
        _handleError('Something went wrong. Please try again.');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _handleError(String message) {
    _error = message;
    messages.add(ChatMessage.local(
      role: 'assistant',
      text: '⚠️ $message',
    ));
  }

  void _showRateLimitMessage() {
    messages.add(ChatMessage.local(
      role: 'assistant',
      text: '⚠️ You have reached the daily limit of '
          '$_dailyLimit messages. Please try again tomorrow.',
    ));
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════
  //  START NEW CHAT
  // ════════════════════════════════════════════════════════

  Future<void> startNewChat() async {
    messages.clear();
    _sessionId = null;
    _isLoading = false;
    _error     = null;
    messageController.clear();
    _addWelcomeMessage();
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════
  //  RESET — on logout
  // ════════════════════════════════════════════════════════

  void reset() {
    messages.clear();
    _sessionId      = null;
    _isLoading      = false;
    _isInitializing = true;
    _error          = null;
    _todayCount     = 0;
    messageController.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }
}