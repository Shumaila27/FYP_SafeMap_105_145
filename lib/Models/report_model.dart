// lib/Models/report_model.dart

class ReportModel {
  final String?   id;
  final String?   userId;
  final String?   categoryId;    // UUID — FK to report_categories
  final String?   categoryName;  // NEW: joined from reports_map_view
  final String?   categoryColor; // NEW: joined from reports_map_view
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

  const ReportModel({
    this.id,
    this.userId,
    this.categoryId,
    this.categoryName,   // NEW
    this.categoryColor,  // NEW
    required this.severity,
    required this.description,
    this.locationAddress,
    this.latitude,
    this.longitude,
    this.incidentTime,
    this.imageUrl,
    this.status      = 'pending',
    this.isAnonymous = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Supabase SELECT / RPC response.
  /// Works for both the raw reports table and reports_map_view —
  /// categoryName / categoryColor are simply null when reading from the table.
  factory ReportModel.fromSupabase(Map<String, dynamic> data) {
    return ReportModel(
      id:              data['id']?.toString(),
      userId:          data['user_id']?.toString(),
      categoryId:      data['category_id']?.toString(),
      categoryName:    data['category_name'],   // null-safe: absent key → null
      categoryColor:   data['category_color'],  // null-safe
      severity:        data['severity'] ?? 'medium',
      description:     data['description'] ?? '',
      locationAddress: data['location_address'],
      latitude:        (data['latitude']  as num?)?.toDouble(),
      longitude:       (data['longitude'] as num?)?.toDouble(),
      incidentTime:    data['incident_time'] != null
          ? DateTime.parse(data['incident_time'])
          : null,
      imageUrl:        data['image_url'],
      status:          data['status'] ?? 'pending',
      isAnonymous:     data['is_anonymous'] ?? true,
      createdAt:       DateTime.parse(data['created_at']),
      updatedAt:       DateTime.parse(data['updated_at']),
    );
  }

  /// Convert to map for Supabase INSERT.
  /// Does NOT include categoryName/categoryColor — those are read-only joins.
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