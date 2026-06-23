// lib/Models/chat_message_model.dart

class ChatMessage {
  final String id;
  final String role;    // 'user' or 'assistant'
  final String text;
  final String time;
  final String sender;  // 'user' or 'bot' — matches your existing UI
  final bool   isLocal; // true = optimistic, not yet in DB

  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.time,
    required this.sender,
    this.isLocal = false,
  });

  // ── From Supabase DB row ───────────────────────────────
  factory ChatMessage.fromMap(Map<String, dynamic> m) {
    final createdAt = DateTime.parse(m['created_at'] as String).toLocal();
    final role      = m['role'] as String;
    return ChatMessage(
      id:      m['id']      as String,
      role:    role,
      text:    m['content'] as String,
      time:    _formatTime(createdAt),
      sender:  role == 'user' ? 'user' : 'bot',
      isLocal: false,
    );
  }

  // ── Local optimistic message ───────────────────────────
  factory ChatMessage.local({
    required String text,
    required String role,
  }) {
    final now = DateTime.now();
    return ChatMessage(
      id:      '${now.millisecondsSinceEpoch}',
      role:    role,
      text:    text,
      time:    _formatTime(now),
      sender:  role == 'user' ? 'user' : 'bot',
      isLocal: true,
    );
  }

  // ── For sending to Gemini API ──────────────────────────
  Map<String, dynamic> toApiMap() => {
    'role':    role,    // 'user' or 'assistant'
    'content': text,
  };

  static String _formatTime(DateTime dt) {
    final h  = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
        ? 12
        : dt.hour;
    final m  = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ap';
  }
}