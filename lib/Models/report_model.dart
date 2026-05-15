// lib/Models/report_model.dart
class ReportModel {
  final String? id;
  final String? userId;
  final String incidentType;
  final String severity;
  final String description;
  final String? locationAddress;
  final double? latitude;
  final double? longitude;
  final DateTime? incidentDate;
  final String? incidentTime;
  final String? imageUrl;
  final String status;
  final bool isAnonymous;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReportModel({
    this.id,
    this.userId,
    required this.incidentType,
    required this.severity,
    required this.description,
    this.locationAddress,
    this.latitude,
    this.longitude,
    this.incidentDate,
    this.incidentTime,
    this.imageUrl,
    this.status = 'pending',
    this.isAnonymous = true,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to Supabase format
  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'user_id': userId,
      'incident_type': incidentType,
      'severity': severity,
      'description': description,
      'location_address': locationAddress,
      'latitude': latitude,
      'longitude': longitude,
      'incident_date': incidentDate?.toIso8601String(),
      'incident_time': incidentTime,
      'image_url': imageUrl,
      'status': status,
      'is_anonymous': isAnonymous,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Create from Supabase response
  factory ReportModel.fromSupabase(Map<String, dynamic> data) {
    return ReportModel(
      id: data['id']?.toString(),
      userId: data['user_id']?.toString(),
      incidentType: data['incident_type'] ?? '',
      severity: data['severity'] ?? 'medium',
      description: data['description'] ?? '',
      locationAddress: data['location_address'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      incidentDate: data['incident_date'] != null
          ? DateTime.parse(data['incident_date'])
          : null,
      incidentTime: data['incident_time'],
      imageUrl: data['image_url'],
      status: data['status'] ?? 'pending',
      isAnonymous: data['is_anonymous'] ?? true,
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
    );
  }

  // Validation
  String? validateIncidentType() {
    if (incidentType.isEmpty) return 'Incident type is required';
    return null;
  }

  String? validateSeverity() {
    if (severity.isEmpty) return 'Severity level is required';
    if (!['low', 'medium', 'high'].contains(severity)) {
      return 'Severity must be low, medium, or high';
    }
    return null;
  }

  String? validateDescription() {
    if (description.isEmpty) return 'Description is required';
    if (description.length < 10) return 'Description must be at least 10 characters';
    if (description.length > 1000) return 'Description must be less than 1000 characters';
    return null;
  }
}

class ReportCategory {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String color;
  final bool isActive;

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
      id: data['id']?.toString() ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? '',
      color: data['color'] ?? '#000000',
      isActive: data['is_active'] ?? true,
    );
  }
}
