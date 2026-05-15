import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Models/report_model.dart';

class ReportService {
  final _client = Supabase.instance.client;

  // ── Submit Report ─────────────────────────────────────
  Future<ReportModel> submitReport({
    required String categoryId,
    required String severity,
    required String description,
    String? locationAddress,
    double? latitude,
    double? longitude,
    DateTime? incidentDate,
    String? incidentTime,
    File? imageFile,
    bool isAnonymous = true,
  }) async {
    try {
      // Upload image if provided
      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await _uploadImage(imageFile);
      }

      // Create report data
      final reportData = {
        'category_id': categoryId,
        'severity': severity,
        'description': description,
        'location_address': locationAddress,
        'latitude': latitude,
        'longitude': longitude,
        'incident_date': incidentDate?.toIso8601String(),
        'incident_time': incidentTime,
        'image_url': imageUrl,
        'is_anonymous': isAnonymous,
        'status': 'pending',
      };

      final response = await _client
          .from('reports')
          .insert(reportData)
          .select()
          .single();

      return ReportModel.fromSupabase(response);
    } catch (e) {
      throw Exception('Failed to submit report: ${e.toString()}');
    }
  }

  // ── Upload Image ─────────────────────────────────────
  Future<String?> _uploadImage(File imageFile) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';

      final path = await _client.storage
          .from('report-images')
          .upload(fileName, imageFile);

      return _client.storage.from('report-images').getPublicUrl(path);
    } catch (e) {
      throw Exception('Image upload failed: ${e.toString()}');
    }
  }

  // ── Get User Reports ───────────────────────────────────
  Future<List<ReportModel>> getUserReports({String? userId}) async {
    try {
      final query = _client.from('reports').select('*');

      // Apply filter if userId exists
      if (userId != null) {
        query.eq('user_id', userId);
      }

      final response = await query.order(
        'created_at',
        ascending: false,
      );

      return (response as List<dynamic>)
          .map((data) => ReportModel.fromSupabase(data))
          .toList();
    } catch (e) {
      throw Exception(
        'Failed to fetch reports: ${e.toString()}',
      );
    }
  }
  // ── Get Nearby Reports ───────────────────────────────
  Future<List<ReportModel>> getNearbyReports({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    try {
      final response = await _client
          .from('reports')
          .select('*')
          .gte('latitude', latitude - radiusKm)
          .lte('latitude', latitude + radiusKm)
          .gte('longitude', longitude - radiusKm)
          .lte('longitude', longitude + radiusKm)
          .order('created_at', ascending: false);

      return (response as List<dynamic>?)
              ?.map((data) => ReportModel.fromSupabase(data))
              .toList() ??
          [];
    } catch (e) {
      throw Exception('Failed to fetch nearby reports: ${e.toString()}');
    }
  }

  // ── Update Report Status ───────────────────────────────
  Future<void> updateReportStatus({
    required String reportId,
    required String status,
    String? notes,
  }) async {
    try {
      await _client
          .from('reports')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .match({'id': reportId});

      // Add status update record
      await _client.from('report_status_updates').insert({
        'report_id': reportId,
        'status': status,
        'notes': notes,
        'updated_by': _client.auth.currentUser?.id,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update report status: ${e.toString()}');
    }
  }

  // ── Get Report Categories ───────────────────────────────
  Future<List<ReportCategory>> getReportCategories() async {
    try {
      final response = await _client
          .from('report_categories')
          .select('*')
          .eq('is_active', true)
          .order('name');

      return (response as List<dynamic>)
          .map((data) => ReportCategory.fromSupabase(data))
          .toList();
    } catch (e) {
      throw Exception(
        'Failed to fetch report categories: ${e.toString()}',
      );
    }
  }

  // ── Delete Report ───────────────────────────────
  Future<void> deleteReport(String reportId) async {
    try {
      await _client.from('reports').delete().match({'id': reportId});
    } catch (e) {
      rethrow;
    }
  }
}
