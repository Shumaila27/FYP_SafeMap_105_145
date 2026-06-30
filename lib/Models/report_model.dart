// lib/Models/report_model.dart

class ReportModel {
  final String?   id;
  final String?   userId;
  final String?   categoryId;    // UUID — FK to report_categories
  final String?   categoryName;  // joined from reports_map_view
  final String?   categoryColor; // joined from reports_map_view
  final String    severity;
  final String    description;
  final String?   locationAddress;
  final double?   latitude;
  final double?   longitude;
  final DateTime? incidentTime;
  final String?   imageUrl;
  final String    status;
  final bool      isAnonymous;
  final DateTime  createdAt;
  final DateTime  updatedAt;

  // ── Validation fields (Method 1: AI Analysis) ──────────────────────────────
  /// AI credibility score 0–100. Null until AI analysis completes.
  final int?    aiScore;

  /// One of: 'credible' | 'suspicious' | 'fake'. Null until AI analysis.
  final String? aiVerdict;

  /// Plain-English reason for the AI score. Null until AI analysis.
  final String? aiReason;

  // ── Validation fields (Method 2: Community Vote) ───────────────────────────
  /// Community confirmation score 0–100. Null until the 30-min window closes.
  final int?    communityScore;

  /// Combined final score = (aiScore × 60%) + (communityScore × 40%).
  /// Null until finalize_report_validation() RPC runs.
  final int?    finalScore;

  /// One of: 'unvalidated' | 'pending_review' | 'verified' | 'flagged_fake'
  final String? validationStatus;

  const ReportModel({
    this.id,
    this.userId,
    this.categoryId,
    this.categoryName,
    this.categoryColor,
    required this.severity,
    required this.description,
    this.locationAddress,
    this.latitude,
    this.longitude,
    this.incidentTime,
    this.imageUrl,
    this.status           = 'pending',
    this.isAnonymous      = true,
    required this.createdAt,
    required this.updatedAt,
    // Validation — all optional so existing code is unaffected
    this.aiScore,
    this.aiVerdict,
    this.aiReason,
    this.communityScore,
    this.finalScore,
    this.validationStatus,
  });

  /// Create from Supabase SELECT / RPC response.
  /// Works for both the raw reports table and reports_map_view.
  /// Validation fields are simply null when the columns don't exist in the
  /// response (e.g. older RPC calls that pre-date the migration).
  factory ReportModel.fromSupabase(Map<String, dynamic> data) {
    return ReportModel(
      id:               data['id']?.toString(),
      userId:           data['user_id']?.toString(),
      categoryId:       data['category_id']?.toString(),
      categoryName:     data['category_name'],
      categoryColor:    data['category_color'],
      severity:         data['severity'] ?? 'medium',
      description:      data['description'] ?? '',
      locationAddress:  data['location_address'],
      latitude:         (data['latitude']  as num?)?.toDouble(),
      longitude:        (data['longitude'] as num?)?.toDouble(),
      incidentTime:     data['incident_time'] != null
          ? DateTime.parse(data['incident_time'])
          : null,
      imageUrl:         data['image_url'],
      status:           data['status'] ?? 'pending',
      isAnonymous:      data['is_anonymous'] ?? true,
      createdAt:        DateTime.parse(data['created_at']),
      updatedAt:        DateTime.parse(data['updated_at']),
      // Validation fields — null-safe (absent key → null)
      aiScore:          (data['ai_score']        as num?)?.toInt(),
      aiVerdict:         data['ai_verdict']       as String?,
      aiReason:          data['ai_reason']        as String?,
      communityScore:   (data['community_score'] as num?)?.toInt(),
      finalScore:       (data['final_score']     as num?)?.toInt(),
      validationStatus:  data['validation_status'] as String?,
    );
  }

  /// Convert to map for Supabase INSERT.
  /// Does NOT include read-only join columns or validation fields
  /// (those are set separately in the insert payload by ReportService).
  Map<String, dynamic> toSupabaseMap() {
    return {
      'category_id':      categoryId,
      'severity':         severity,
      'description':      description.isEmpty ? null : description,
      'location_address': locationAddress,
      'latitude':         latitude,
      'longitude':        longitude,
      'incident_time':    incidentTime?.toIso8601String(),
      'image_url':        imageUrl,
      'status':           status,
      'is_anonymous':     isAnonymous,
    };
  }

  // ── Convenience getters ────────────────────────────────────────────────────

  /// Returns true once the 30-min community vote window has closed and the
  /// final score has been computed by finalize_report_validation().
  bool get isFullyValidated =>
      validationStatus != null && validationStatus != 'unvalidated';

  /// Emoji + label string suitable for display in the UI.
  String get validationLabel {
    switch (validationStatus) {
      case 'verified':      return '✅ Verified';
      case 'flagged_fake':  return '⚠️ Flagged as Fake';
      case 'pending_review': return '⏳ Pending Review';
      default:              return '🔄 Unvalidated';
    }
  }
}

/// Matches report_categories table
class ReportCategory {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String color;
  final bool   isActive;

  const ReportCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.isActive = true,
  });

  factory ReportCategory.fromSupabase(Map<String, dynamic> data) {
    return ReportCategory(
      id:          data['id']?.toString() ?? '',
      name:        data['name'] ?? '',
      description: data['description'] ?? '',
      icon:        data['icon'] ?? '',
      color:       data['color'] ?? '#000000',
      isActive:    data['is_active'] ?? true,
    );
  }
}