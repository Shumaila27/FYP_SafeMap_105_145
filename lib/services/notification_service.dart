// lib/services/notification_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _supabase = Supabase.instance.client;

  // ── Get OAuth2 access token from service account ──────────
  Future<String> _getAccessToken() async {
    final jsonString = await rootBundle
        .loadString('assets/service_account.json');
    final jsonMap = json.decode(jsonString);

    final credentials = ServiceAccountCredentials.fromJson(jsonMap);
    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

    final client = await clientViaServiceAccount(credentials, scopes);
    final token  = client.credentials.accessToken.data;
    client.close();

    return token;
  }

  // ── Send notification to a single FCM token ───────────────
  Future<void> _sendToToken({
    required String fcmToken,
    required String title,
    required String body,
    required Map<String, String> data,
  }) async {
    try {
      final accessToken = await _getAccessToken();

      // Get your Firebase project ID from service_account.json
      final jsonString = await rootBundle
          .loadString('assets/service_account.json');
      final projectId  = json.decode(jsonString)['project_id'] as String;

      final url = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
      );

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type':  'application/json',
        },
        body: json.encode({
          'message': {
            'token': fcmToken,
            'notification': {
              'title': title,
              'body':  body,
            },
            'data': data,
            'android': {
              'priority': 'high',
              'notification': {
                'sound':        'default',
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                'channel_id':   'community_vote',
              },
            },
            'apns': {
              'payload': {
                'aps': {
                  'sound': 'default',
                },
              },
            },
          },
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('[FCM] Notification sent successfully');
      } else {
        debugPrint('[FCM] Failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('[FCM] Error sending notification: $e');
    }
  }

  // ── Send Safe Walk notification to all guardians ──────────
  Future<void> notifyGuardiansSafeWalkStarted({
    required String walkId,
    required String walkerName,
    required String destination,
    required List<String> guardianProfileIds,
  }) async {
    if (guardianProfileIds.isEmpty) return;

    try {
      // Fetch FCM tokens of all guardians
      final rows = await _supabase
          .from('profiles')
          .select('fcm_token')
          .inFilter('id', guardianProfileIds);

      final tokens = rows
          .map((r) => r['fcm_token'] as String?)
          .where((t) => t != null && t.isNotEmpty)
          .cast<String>()
          .toList();

      debugPrint('[FCM] Sending to ${tokens.length} guardians');

      // Send notification to each guardian
      for (final token in tokens) {
        await _sendToToken(
          fcmToken: token,
          title:    '🛡️ Safe Walk Started',
          body:     '$walkerName started a Safe Walk to $destination. Tap to track.',
          data: {
            'type':    'safe_walk_started',
            'walk_id': walkId,
            'screen':  'map',
          },
        );
      }
    } catch (e) {
      debugPrint('[FCM] notifyGuardians error: $e');
    }
  }

  // ── Send Safe Walk ended notification ─────────────────────
  Future<void> notifyGuardiansSafeWalkEnded({
    required String walkerName,
    required List<String> guardianProfileIds,
  }) async {
    if (guardianProfileIds.isEmpty) return;

    try {
      final rows = await _supabase
          .from('profiles')
          .select('fcm_token')
          .inFilter('id', guardianProfileIds);

      final tokens = rows
          .map((r) => r['fcm_token'] as String?)
          .where((t) => t != null && t.isNotEmpty)
          .cast<String>()
          .toList();

      for (final token in tokens) {
        await _sendToToken(
          fcmToken: token,
          title:    '✅ Safe Walk Ended',
          body:     '$walkerName has arrived safely!',
          data: {
            'type':   'safe_walk_ended',
            'screen': 'map',
          },
        );
      }
    } catch (e) {
      debugPrint('[FCM] notifyWalkEnded error: $e');
    }
  }

  // ── Send Emergency notification ────────────────────────────
  Future<void> notifyGuardiansEmergency({
    required String walkerName,
    required double lat,
    required double lng,
    required List<String> guardianProfileIds,
  }) async {
    if (guardianProfileIds.isEmpty) return;

    try {
      final rows = await _supabase
          .from('profiles')
          .select('fcm_token')
          .inFilter('id', guardianProfileIds);

      final tokens = rows
          .map((r) => r['fcm_token'] as String?)
          .where((t) => t != null && t.isNotEmpty)
          .cast<String>()
          .toList();

      for (final token in tokens) {
        await _sendToToken(
          fcmToken: token,
          title:    '🚨 EMERGENCY ALERT',
          body:     '$walkerName needs immediate help! Tap to see location.',
          data: {
            'type':   'emergency',
            'lat':    lat.toString(),
            'lng':    lng.toString(),
            'screen': 'map',
          },
        );
      }
    } catch (e) {
      debugPrint('[FCM] notifyEmergency error: $e');
    }
  }

  // ── Send Nearby SOS notification ────────────────────────────
  Future<void> notifyNearbyUsersSOS({
    required double lat,
    required double lng,
    required List<String> fcmTokens,
  }) async {
    if (fcmTokens.isEmpty) return;

    try {
      debugPrint('[FCM] Sending SOS alert to ${fcmTokens.length} nearby users');
      for (final token in fcmTokens) {
        await _sendToToken(
          fcmToken: token,
          title:    '🚨 NEARBY SOS ALERT',
          body:     'A nearby SafeMap user has triggered an SOS alert! Tap to open map.',
          data: {
            'type':   'nearby_sos',
            'lat':    lat.toString(),
            'lng':    lng.toString(),
            'screen': 'map',
          },
        );
      }
    } catch (e) {
      debugPrint('[FCM] notifyNearbyUsersSOS error: $e');
    }
  }

  // ── Send Community Vote notification (report validation) ─────────────────
  /// Sends "Did you witness this?" notifications to nearby users so they
  /// can confirm or deny a newly submitted incident report.
  ///
  /// Called exclusively by [CommunityVoteService.notifyNearbyUsers] —
  /// this keeps all FCM sending logic inside [NotificationService].
  Future<void> notifyNearbyUsersCommunityVote({
    required String       reportId,
    required String       categoryName,
    required String       description,
    required List<String> fcmTokens,
  }) async {
    if (fcmTokens.isEmpty) return;

    try {
      debugPrint(
        '[FCM] Sending community vote notification to '
        '${fcmTokens.length} nearby users for report $reportId',
      );

      for (final token in fcmTokens) {
        await _sendToToken(
          fcmToken: token,
          title:    '🔍 Incident Near You — Did You See This?',
          body:     '${_capitalize(categoryName)}: $description',
          data: {
            'type':          'community_vote',
            'report_id':     reportId,
            'category_name': categoryName,   // ✅ NEW — passed to VoteScreen
            'description':   description,    // ✅ NEW — passed to VoteScreen
            'screen':        'vote',
          },
        );
      }
    } catch (e) {
      debugPrint('[FCM] notifyNearbyUsersCommunityVote error: $e');
    }
  }

  // ── Helper ────────────────────────────────────────────────────────────────
  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}