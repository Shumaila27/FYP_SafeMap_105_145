// lib/services/report_service.dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Models/report_model.dart';

// ── Custom Exceptions ──────────────────────────────────────────────────────

class ImageUploadException implements Exception {
  final String message;
  const ImageUploadException(this.message);
}

class ReportSubmitException implements Exception {
  final String message;
  const ReportSubmitException(this.message);
}

// ── Service ────────────────────────────────────────────────────────────────

class ReportService {
  final _client = Supabase.instance.client;

  // ── Submit Report ──────────────────────────────────────────────────────────
  Future<ReportModel> submitReport({
    required String categoryName,
    required String severity,
    required String description,
    String? locationAddress,
    double? latitude,
    double? longitude,
    DateTime? incidentTime,
    File? imageFile,
    bool isAnonymous = true,
  }) async {
    // 1. Resolve category name → UUID
    String categoryId;
    try {
      final catRow = await _client
          .from('report_categories')
          .select('id')
          .eq('name', categoryName)
          .single();
      categoryId = catRow['id'] as String;
    } catch (e) {
      throw ReportSubmitException(
          'Unknown incident category "$categoryName". Please try again.');
    }

    // 2. Upload image before insert — track fileName for orphan cleanup
    String? imageUrl;
    String? uploadedFileName;
    if (imageFile != null) {
      try {
        uploadedFileName =
        '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';

        // Upload the file — discard the returned path (it includes bucket name)
        await _client.storage
            .from('report_images')
            .upload(uploadedFileName, imageFile);

        // ✅ FIX: Use uploadedFileName directly — NOT the returned path.
        // upload() returns "report_images/filename.jpg" which causes
        // getPublicUrl() to double the bucket name in the URL.
        imageUrl = _client.storage
            .from('report_images')
            .getPublicUrl(uploadedFileName);

      } catch (e) {
        throw ImageUploadException(
            'Photo upload failed. Your report was not submitted. '
                'Please try again or submit without a photo.');
      }
    }

    // 3. Insert report
    try {
      final reportData = {
        'category_id': categoryId,
        'severity': severity,
        'description': description.isEmpty ? null : description,
        'location_address': locationAddress,
        'latitude': latitude,
        'longitude': longitude,
        'incident_time': (incidentTime ?? DateTime.now()).toIso8601String(),
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
      // Orphan cleanup — delete the uploaded image if the DB insert failed
      if (uploadedFileName != null) {
        try {
          await _client.storage
              .from('report_images')
              .remove([uploadedFileName]);
        } catch (_) {}
      }
      throw ReportSubmitException(
          'Failed to save your report. Please check your connection and try again.');
    }
  }

  // ── Get Nearby Reports (PostGIS RPC + Pagination) ─────────────────────────
  Future<List<ReportModel>> getNearbyReports({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    int page = 0,
    int pageSize = 50,
  }) async {
    try {
      final response = await _client.rpc(
        'get_nearby_reports',
        params: {
          'user_lat': latitude,
          'user_lng': longitude,
          'radius_m': radiusKm * 1000, // km → metres for ST_DWithin
          'page_limit': pageSize,
          'page_offset': page * pageSize,
        },
      );

      return (response as List<dynamic>)
          .map((d) => ReportModel.fromSupabase(d as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch nearby reports: $e');
    }
  }

  // ── Get User Reports ───────────────────────────────────────────────────────
  Future<List<ReportModel>> getUserReports({String? userId}) async {
    try {
      var query = _client.from('reports').select('*');
      if (userId != null) {
        query = query.eq('user_id', userId);
      }
      final response = await query.order('created_at', ascending: false);
      return (response as List<dynamic>)
          .map((d) => ReportModel.fromSupabase(d))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch reports: $e');
    }
  }

  // ── Update Report Status ───────────────────────────────────────────────────
  Future<void> updateReportStatus({
    required String reportId,
    required String status,
    String? notes,
  }) async {
    try {
      await _client
          .from('reports')
          .update({'status': status}).eq('id', reportId);
    } catch (e) {
      throw Exception('Failed to update report status: $e');
    }
  }

  // ── Get Report Categories ──────────────────────────────────────────────────
  Future<List<ReportCategory>> getReportCategories() async {
    try {
      final response = await _client
          .from('report_categories')
          .select('*')
          .eq('is_active', true)
          .order('name');
      return (response as List<dynamic>)
          .map((d) => ReportCategory.fromSupabase(d))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch report categories: $e');
    }
  }

  // ── Delete Report ──────────────────────────────────────────────────────────
  Future<void> deleteReport(String reportId) async {
    try {
      await _client.from('reports').delete().eq('id', reportId);
    } catch (e) {
      rethrow;
    }
  }
}