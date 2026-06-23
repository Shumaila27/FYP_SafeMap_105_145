// lib/services/chat_service.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Models/chat_message_model.dart';

class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  final _client = Supabase.instance.client;

  String get _uid {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('User not authenticated');
    return uid;
  }

  // ════════════════════════════════════════════════════════
  //  SESSION MANAGEMENT
  // ════════════════════════════════════════════════════════

  /// Create brand new chat session
  Future<String> createSession(String firstMessage) async {
    final title = firstMessage.length > 40
        ? '${firstMessage.substring(0, 40)}...'
        : firstMessage;

    final row = await _client
        .from('chat_sessions')
        .insert({
      'user_id': _uid,
      'title':   title,
    })
        .select()
        .single();

    return row['id'] as String;
  }

  /// Load most recent session ID for persistence
  Future<String?> loadLatestSessionId() async {
    try {
      final row = await _client
          .from('chat_sessions')
          .select('id')
          .eq('user_id', _uid)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return row?['id'] as String?;
    } catch (e) {
      debugPrint('[ChatService] loadLatestSessionId error: $e');
      return null;
    }
  }

  /// Load all sessions (for future chat history screen)
  Future<List<Map<String, dynamic>>> loadAllSessions() async {
    try {
      final rows = await _client
          .from('chat_sessions')
          .select('id, title, updated_at')
          .eq('user_id', _uid)
          .order('updated_at', ascending: false)
          .limit(20);

      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      debugPrint('[ChatService] loadAllSessions error: $e');
      return [];
    }
  }

  /// Delete a session — messages auto-delete via DB cascade
  Future<void> deleteSession(String sessionId) async {
    await _client
        .from('chat_sessions')
        .delete()
        .eq('id', sessionId);
  }

  // ════════════════════════════════════════════════════════
  //  MESSAGES
  // ════════════════════════════════════════════════════════

  /// Load all messages for a session
  Future<List<ChatMessage>> loadMessages(String sessionId) async {
    try {
      final rows = await _client
          .from('chat_messages')
          .select('*')
          .eq('session_id', sessionId)
          .order('created_at');

      return rows.map((r) => ChatMessage.fromMap(r)).toList();
    } catch (e) {
      debugPrint('[ChatService] loadMessages error: $e');
      return [];
    }
  }

  // ════════════════════════════════════════════════════════
  //  SEND MESSAGE → EDGE FUNCTION → GEMINI → SAVE
  // ════════════════════════════════════════════════════════

  Future<String> sendMessage({
    required String            sessionId,
    required String            userMessage,
    required List<ChatMessage> history,
    List<Map<String, dynamic>>? nearbyReports,
  }) async {
    // 1. Save user message to DB first
    await _client.from('chat_messages').insert({
      'session_id': sessionId,
      'user_id':    _uid,
      'role':       'user',
      'content':    userMessage,
    });

    // 2. Build history for Gemini — last 10 messages only
    //    to keep costs low and stay within token limits
    final recent = history.length > 10
        ? history.sublist(history.length - 10)
        : history;

    final apiMessages = [
      ...recent.map((m) => m.toApiMap()),
      {'role': 'user', 'content': userMessage},
    ];

    // 3. Call Supabase Edge Function
    //    Edge function holds Gemini API key safely
    final response = await _client.functions.invoke(
      'ai-chat',
      body: {
        'messages':      apiMessages,
        'nearbyReports': nearbyReports ?? [],
      },
    );
    // ✅ ADD THESE DEBUG
    debugPrint('📥 Response status: ${response.status}');
    debugPrint('📥 Response data: ${response.data}');

    // 4. Handle response errors
    if (response.data == null) {
      throw Exception('No response from server');
    }

    final error = response.data['error'] as String?;
    if (error != null) throw Exception(error);

    final reply = response.data['reply'] as String?;
    if (reply == null || reply.isEmpty) {
      throw Exception('Empty response from AI');
    }

    // 5. Save AI reply to DB
    await _client.from('chat_messages').insert({
      'session_id': sessionId,
      'user_id':    _uid,
      'role':       'assistant',
      'content':    reply,
    });

    // 6. Update session timestamp
    //    DB trigger also handles this (Fix #5) but explicit is safer
    await _client
        .from('chat_sessions')
        .update({
      'updated_at': DateTime.now().toIso8601String(),
    })
        .eq('id', sessionId);

    return reply;
  }

  // ════════════════════════════════════════════════════════
  //  RATE LIMIT — client side check
  // ════════════════════════════════════════════════════════

  Future<int> getTodayMessageCount() async {
    try {
      final today =
      DateTime.now().toIso8601String().split('T')[0];

      final row = await _client
          .from('chat_rate_limits')
          .select('message_count')
          .eq('user_id', _uid)
          .eq('message_date', today)
          .maybeSingle();

      return row?['message_count'] as int? ?? 0;
    } catch (e) {
      debugPrint('[ChatService] getTodayMessageCount error: $e');
      return 0;
    }
  }
}