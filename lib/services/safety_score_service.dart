// lib/services/safety_score_service.dart
import 'package:flutter/material.dart';
import '../Models/report_model.dart';

/// Pure, stateless service — no Supabase, no Flutter deps beyond Color.
/// Call [calculate] with whatever reports are currently visible on the map.
class SafetyScoreService {
  SafetyScoreService._(); // prevent instantiation

  // ── Weights ────────────────────────────────────────────────────────────────
  static const double _highWeight   = 15.0;
  static const double _mediumWeight =  7.0;
  static const double _lowWeight    =  3.0;

  // Recency multipliers — recent incidents hurt the score more
  static const double _last24h    = 1.0;
  static const double _last7days  = 0.6;
  static const double _last30days = 0.3;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns an integer 0–100.
  /// 100 = no incidents in the area.
  /// 0   = extremely high concentration of recent high-risk incidents.
  static int calculate(List<ReportModel> reports) {
    if (reports.isEmpty) return 100;

    final now = DateTime.now();
    double totalPenalty = 0;

    for (final report in reports) {
      final age = now.difference(report.incidentTime ?? now);
      final recency = _recencyMultiplier(age);
      final severity = _severityWeight(report.severity);
      totalPenalty += severity * recency;
    }

    // Scale: 100 penalty points → score 0; 0 penalty → score 100
    // Clamp so it never goes negative.
    final score = (100 - totalPenalty).clamp(0, 100).toInt();
    return score;
  }

  /// Colour that reflects the score for UI display.
  static Color scoreColor(int score) {
    if (score >= 75) return Colors.green.shade600;
    if (score >= 50) return Colors.orange.shade500;
    return Colors.red.shade600;
  }

  /// One-word label for the score.
  static String scoreLabel(int score) {
    if (score >= 75) return 'Safe';
    if (score >= 50) return 'Moderate';
    return 'Dangerous';
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static double _severityWeight(String severity) {
    switch (severity) {
      case 'high':   return _highWeight;
      case 'medium': return _mediumWeight;
      default:       return _lowWeight;
    }
  }

  static double _recencyMultiplier(Duration age) {
    if (age.inHours < 24)   return _last24h;
    if (age.inDays  < 7)    return _last7days;
    return _last30days;
  }
}