// lib/services/community_vote_service.dart
//
// ──────────────────────────────────────────────────────────────
//  CommunityVoteService  (Method 2 — Community Confirmation)
//
//  After a report is saved:
//  1. Finds all users within 5 km using the existing
//     get_nearby_users_fcm_tokens PostGIS RPC.
//  2. Pushes an FCM notification: "Did you witness this incident?"
//     (reuses NotificationService — does NOT create a new FCM service)
//  3. Accepts Yes/No votes from nearby users via castVote().
//  4. After 30 minutes, calls finalize_report_validation() RPC which
//     computes community_score, final_score, and validation_status.
//
//  Final Score = (ai_score × 60%) + (community_score × 40%)
//    80–100 → verified ✅
//    50–79  → pending_review ⏳
//    0–49   → flagged_fake ⚠️
//
//  NOTE: The 30-minute Timer runs on the main Dart isolate.
//  If the app is fully terminated the timer will not fire —
//  a Supabase scheduled job can be added later for production.
// ──────────────────────────────────────────────────────────────

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'notification_service.dart';

// ── Result Model ──────────────────────────────────────────────────────────────

class CommunityVoteResult {
  final int    communityScore;     // 0–100
  final int    finalScore;         // 0–100  (ai×60% + community×40%)
  final String validationStatus;   // verified | pending_review | flagged_fake
  final int    yesVotes;
  final int    totalVotes;

  const CommunityVoteResult({
    required this.communityScore,
    required this.finalScore,
    required this.validationStatus,
    required this.yesVotes,
    required this.totalVotes,
  });

  factory CommunityVoteResult.fromJson(Map<String, dynamic> json) {
    return CommunityVoteResult(
      communityScore:   (json['community_score']   as num?)?.toInt() ?? 50,
      finalScore:       (json['final_score']       as num?)?.toInt() ?? 50,
      validationStatus: json['validation_status']  as String? ?? 'pending_review',
      yesVotes:         (json['yes_votes']         as num?)?.toInt() ?? 0,
      totalVotes:       (json['total_votes']       as num?)?.toInt() ?? 0,
    );
  }

  /// Human-readable emoji label for the validation status.
  String get statusLabel {
    switch (validationStatus) {
      case 'verified':      return '✅ Verified';
      case 'flagged_fake':  return '⚠️ Flagged as Fake';
      default:              return '⏳ Pending Review';
    }
  }

  @override
  String toString() =>
      'CommunityVoteResult(status: $validationStatus, final: $finalScore, '
      'votes: $yesVotes/$totalVotes)';
}

// ── Service ───────────────────────────────────────────────────────────────────

class CommunityVoteService {
  CommunityVoteService._();
  static final CommunityVoteService instance = CommunityVoteService._();

  final _client = Supabase.instance.client;

  // Active finalization timers keyed by reportId.
  // Only one timer per report is allowed at a time.
  final Map<String, Timer> _timers = {};

  // ════════════════════════════════════════════════════════════════════════════
  //  STEP 1 — NOTIFY NEARBY USERS
  // ════════════════════════════════════════════════════════════════════════════

  /// Finds all SafeMap users within [radiusM] metres of the report location
  /// using the existing `get_nearby_users_fcm_tokens` PostGIS RPC, then sends
  /// each of them an FCM push notification asking if they witnessed the incident.
  ///
  /// The submitting user is automatically excluded from the notification list.
  Future<void> notifyNearbyUsers({
    required String reportId,
    required double latitude,
    required double longitude,
    required String categoryName,
    required String description,
    double radiusM = 5000.0,  // 5 km default
  }) async {
    try {
      final uid = _client.auth.currentUser?.id;

      // Reuse the PostGIS RPC already defined in panic_alerts.sql
      final response = await _client.rpc(
        'get_nearby_users_fcm_tokens',
        params: {
          'p_user_lat':        latitude,
          'p_user_lng':        longitude,
          'p_radius_m':        radiusM,
          // Exclude the submitting user so they don't vote on their own report
          'p_exclude_user_id': uid ?? '00000000-0000-0000-0000-000000000000',
        },
      );

      if (response == null) {
        debugPrint('[CommunityVote] RPC returned null — no users notified.');
        return;
      }

      final fcmTokens = (response as List).cast<String>().toList();

      if (fcmTokens.isEmpty) {
        debugPrint('[CommunityVote] No nearby users found within $radiusM m.');
        return;
      }

      debugPrint('[CommunityVote] Notifying ${fcmTokens.length} nearby users.');

      // Truncate description for notification body
      final shortDesc = description.length > 60
          ? '${description.substring(0, 60)}…'
          : description;

      // Send via the existing NotificationService (does NOT create a new service)
      await NotificationService.instance.notifyNearbyUsersCommunityVote(
        reportId:     reportId,
        categoryName: categoryName,
        description:  shortDesc,
        fcmTokens:    fcmTokens,
      );
    } catch (e) {
      debugPrint('[CommunityVote] notifyNearbyUsers error: $e');
      // Non-fatal — submission already succeeded, notification is best-effort
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  STEP 2 — CAST A VOTE
  // ════════════════════════════════════════════════════════════════════════════

  /// Records the current user's vote for a report.
  ///
  /// [witnessed] = true  → "Yes, I saw this incident"
  /// [witnessed] = false → "No, I did not see this"
  ///
  /// Throws [Exception] if the user has already voted or is not authenticated.
  Future<void> castVote({
    required String reportId,
    required bool   witnessed,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('User not authenticated');

    try {
      await _client.from('report_votes').insert({
        'report_id': reportId,
        'voter_id':  uid,
        'vote':      witnessed,
      });
      debugPrint(
        '[CommunityVote] Vote cast: witnessed=$witnessed for report $reportId',
      );
    } on PostgrestException catch (e) {
      // code 23505 = unique_violation (CONSTRAINT uq_report_voter)
      if (e.code == '23505') {
        throw Exception('You have already voted on this report.');
      }
      debugPrint('[CommunityVote] castVote DB error: ${e.message}');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  STEP 3 — FINALIZE VOTES
  // ════════════════════════════════════════════════════════════════════════════

  /// Calls the `finalize_report_validation` Supabase RPC which:
  ///   - counts yes/no votes
  ///   - computes community_score, final_score, validation_status
  ///   - writes results back to the `reports` table
  ///
  /// Returns [CommunityVoteResult] or null on error.
  Future<CommunityVoteResult?> finalizeVotes(String reportId) async {
    try {
      final response = await _client.rpc(
        'finalize_report_validation',
        params: {'p_report_id': reportId},
      );

      if (response == null) {
        debugPrint('[CommunityVote] finalize RPC returned null.');
        return null;
      }

      final json   = Map<String, dynamic>.from(response as Map);
      final result = CommunityVoteResult.fromJson(json);

      debugPrint('[CommunityVote] Finalized → $result');
      return result;
    } catch (e) {
      debugPrint('[CommunityVote] finalizeVotes error: $e');
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  SCHEDULE FINALIZATION
  // ════════════════════════════════════════════════════════════════════════════

  /// Schedules [finalizeVotes] to run after [window] (default: 30 minutes).
  ///
  /// Only one timer per report ID is kept — calling this again for the
  /// same report cancels the previous timer and starts a fresh one.
  ///
  /// ⚠️ Timer runs on the main Dart isolate. If the app process is killed,
  ///    the timer will not fire. For production, pair this with a Supabase
  ///    pg_cron job that calls finalize_report_validation periodically.
  void scheduleFinalization(
    String reportId, {
    Duration window = const Duration(minutes: 30),
  }) {
    // Cancel any existing timer for this report
    _timers[reportId]?.cancel();

    _timers[reportId] = Timer(window, () async {
      debugPrint(
        '[CommunityVote] ⏰ Finalization timer fired for report $reportId',
      );
      await finalizeVotes(reportId);
      _timers.remove(reportId);
    });

    debugPrint(
      '[CommunityVote] Finalization scheduled in '
      '${window.inMinutes} min for report $reportId',
    );
  }

  /// Cancels a pending finalization timer (e.g. when a report is deleted).
  void cancelFinalization(String reportId) {
    _timers[reportId]?.cancel();
    _timers.remove(reportId);
    debugPrint('[CommunityVote] Finalization cancelled for report $reportId');
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  READ HELPERS
  // ════════════════════════════════════════════════════════════════════════════

  /// Fetch the current vote counts for a report (for UI display).
  Future<({int yes, int no, int total})> getVoteCounts(String reportId) async {
    try {
      final rows = await _client
          .from('report_votes')
          .select('vote')
          .eq('report_id', reportId);

      final yes   = (rows as List).where((r) => r['vote'] == true).length;
      final total = rows.length;
      return (yes: yes, no: total - yes, total: total);
    } catch (e) {
      debugPrint('[CommunityVote] getVoteCounts error: $e');
      return (yes: 0, no: 0, total: 0);
    }
  }

  /// Returns true if the current user has already voted on [reportId].
  Future<bool> hasUserVoted(String reportId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return false;
    try {
      final row = await _client
          .from('report_votes')
          .select('id')
          .eq('report_id', reportId)
          .eq('voter_id', uid)
          .maybeSingle();
      return row != null;
    } catch (_) {
      return false;
    }
  }
}
