// lib/services/panic_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_service.dart';
import 'notification_service.dart';

// ── Models ───────────────────────────────────────────────────

class PanicAlert {
  final String id;
  final String userId;
  final double latitude;
  final double longitude;
  final String status;
  final DateTime createdAt;
  final String? userName; // Only populated on initial inserts/fetches via joins

  const PanicAlert({
    required this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.createdAt,
    this.userName,
  });

  factory PanicAlert.fromMap(Map<String, dynamic> m) {
    return PanicAlert(
      id:        m['id'] as String,
      userId:    m['user_id'] as String,
      latitude:  (m['latitude'] as num).toDouble(),
      longitude: (m['longitude'] as num).toDouble(),
      status:    m['status'] as String,
      createdAt: DateTime.parse(m['created_at'] as String),
      userName:  m['profiles'] != null ? m['profiles']['name'] as String? : null,
    );
  }

  bool get isActive => status == 'active';
}

// ── Service ──────────────────────────────────────────────────

class PanicService {
  PanicService._();
  static final PanicService instance = PanicService._();

  final _client = Supabase.instance.client;

  String get _uid {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('User not authenticated');
    return uid;
  }

  /// Triggers panic mode: saves alert to DB, notifies guardians and nearby users.
  Future<PanicAlert> triggerPanicMode(double lat, double lng) async {
    // 1. Save panic alert to DB with a join to profiles to get the user's name
    final row = await _client.from('panic_alerts').insert({
      'user_id':   _uid,
      'latitude':  lat,
      'longitude': lng,
      'status':    'active',
    }).select('*, profiles(name)').single();

    final alert = PanicAlert.fromMap(row);
    final userName = alert.userName ?? 'A SafeMap user';

    // 2. Fetch emergency contacts and alert them via FCM
    try {
      final contacts = await ProfileService.instance.fetchContacts();
      final guardianIds = contacts
          .where((c) => c.guardianProfileId != null)
          .map((c) => c.guardianProfileId!)
          .toList();

      if (guardianIds.isNotEmpty) {
        await NotificationService.instance.notifyGuardiansEmergency(
          walkerName: userName,
          lat: lat,
          lng: lng,
          guardianProfileIds: guardianIds,
        );
      }
    } catch (e) {
      debugPrint('[PanicService] Error notifying guardians: $e');
    }

    // 3. Find nearby users' FCM tokens using RPC and notify them (within 5km)
    try {
      final response = await _client.rpc(
        'get_nearby_users_fcm_tokens',
        params: {
          'p_user_lat':        lat,
          'p_user_lng':        lng,
          'p_radius_m':        5000.0,
          'p_exclude_user_id': _uid,
        },
      );

      if (response != null) {
        final fcmTokens = (response as List).cast<String>().toList();
        if (fcmTokens.isNotEmpty) {
          await NotificationService.instance.notifyNearbyUsersSOS(
            lat: lat,
            lng: lng,
            fcmTokens: fcmTokens,
          );
        }
      }
    } catch (e) {
      debugPrint('[PanicService] Error notifying nearby users: $e');
    }

    return alert;
  }

  /// Resolves an active panic alert.
  Future<void> resolvePanicMode(String alertId) async {
    await _client.from('panic_alerts').update({
      'status': 'resolved',
    }).eq('id', alertId);
    debugPrint('[PanicService] Resolved panic alert: $alertId');
  }

  /// Streams active panic alerts in real-time.
  Stream<List<PanicAlert>> activePanicAlertsStream() {
    return _client
        .from('panic_alerts')
        .stream(primaryKey: ['id'])
        .eq('status', 'active')
        .map((rows) => rows.map((r) => PanicAlert.fromMap(r)).toList());
  }
}
