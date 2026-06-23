// lib/services/fcm_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FCMService {
  FCMService._();
  static final FCMService instance = FCMService._();

  final _messaging = FirebaseMessaging.instance;
  final _supabase   = Supabase.instance.client;

  // ── Call this after user logs in ──────────────────────────
  Future<void> saveTokenToSupabase() async {
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) return;

      // Get this device's unique FCM token
      final token = await _messaging.getToken();
      if (token == null) return;

      // Save it to profiles table
      await _supabase
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', uid);

      debugPrint('[FCM] Token saved: $token');

      // If token refreshes in future, save the new one automatically
      _messaging.onTokenRefresh.listen((newToken) async {
        await _supabase
            .from('profiles')
            .update({'fcm_token': newToken})
            .eq('id', uid);
        debugPrint('[FCM] Token refreshed and saved');
      });

    } catch (e) {
      debugPrint('[FCM] Error saving token: $e');
    }
  }
}