// lib/services/report_service.dart
//
// ──────────────────────────────────────────────────────────────
//  ReportService  (v2 — Report Validation Integration)
//
//  submitReport() now runs a two-stage validation pipeline:
//
//  Method 1 — AI Analysis (BEFORE DB insert)
//    ReportValidationService calls Gemini 2.0 Flash with the image,
//    description, category, location and timestamp.
//    → Writes ai_score, ai_verdict, ai_reason to the report row.
//
//  Method 2 — Community Confirmation (AFTER DB insert, fire-and-forget)
//    CommunityVoteService finds users within 5 km via PostGIS RPC and
//    pushes FCM notifications asking "Did you witness this?"
//    A 30-min Timer then calls finalize_report_validation() RPC to
//    compute community_score + final_score + validation_status.
//
//  Final Score = (ai_score × 60%) + (community_score × 40%)
//    80–100 → verified ✅   50–79 → pending_review ⏳   0–49 → flagged_fake ⚠️
//
//  All other public methods (getNearbyReports, getUserReports, etc.)
//  are unchanged — existing callers need zero modifications.
// ──────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Models/report_model.dart';
import 'report_validation_service.dart';
import 'community_vote_service.dart';

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
    required String  categoryName,
    required String  severity,
    required String  description,
    String?          locationAddress,
    double?          latitude,
    double?          longitude,
    DateTime?        incidentTime,
    File?            imageFile,
    bool             isAnonymous = true,
  }) async {

    // ── STEP 1: Resolve category name → UUID ────────────────────────────────
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

    // ── STEP 2: Upload image (before insert — track name for orphan cleanup) ─
    String? imageUrl;
    String? uploadedFileName;
    if (imageFile != null) {
      try {
        uploadedFileName =
            '${DateTime.now().millisecondsSinceEpoch}_'
            '${imageFile.path.split('/').last}';

        await _client.storage
            .from('report_images')
            .upload(uploadedFileName, imageFile);

        // Use uploadedFileName directly — NOT the returned path.
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

    // ── STEP 3: AI Validation — Method 1 (BEFORE DB insert) ─────────────────
    // On any API failure, neutral score (50) is returned and submission proceeds.
    AiValidationResult aiResult;
    try {
      debugPrint('[ReportService] Running AI validation…');
      aiResult = await ReportValidationService.instance.analyseReport(
        categoryName:    categoryName,
        description:     description,
        locationAddress: locationAddress,
        incidentTime:    incidentTime,
        imageFile:       imageFile,
      );
      debugPrint('[ReportService] AI result: $aiResult');
    } catch (e) {
      debugPrint('[ReportService] AI validation threw unexpectedly: $e');
      aiResult = AiValidationResult.neutral();
    }

    // ── STEP 4: Insert report WITH AI scores ─────────────────────────────────
    ReportModel report;
    try {
      final reportData = {
        'category_id':       categoryId,
        'severity':          severity,
        'description':       description.isEmpty ? null : description,
        'location_address':  locationAddress,
        'latitude':          latitude,
        'longitude':         longitude,
        'incident_time':     (incidentTime ?? DateTime.now()).toIso8601String(),
        'image_url':         imageUrl,
        'is_anonymous':      isAnonymous,
        'status':            'pending',
        // Method 1 — AI validation (stored immediately)
        'ai_score':          aiResult.aiScore,
        'ai_verdict':        aiResult.verdict,
        'ai_reason':         aiResult.reason,
        // Method 2 columns are written later by finalize_report_validation()
        'validation_status': 'pending_review',
      };

      final response = await _client
          .from('reports')
          .insert(reportData)
          .select()
          .single();

      report = ReportModel.fromSupabase(response);
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

    // ── STEP 5: Community voting — fire-and-forget (Method 2) ───────────────
    // Only possible when GPS coordinates are available.
    // Runs asynchronously — errors here never affect the returned report.
    if (latitude != null && longitude != null && report.id != null) {
      final reportId = report.id!;

      // 5a. Push FCM notifications to nearby users (ignore errors)
      CommunityVoteService.instance.notifyNearbyUsers(
        reportId:     reportId,
        latitude:     latitude,
        longitude:    longitude,
        categoryName: categoryName,
        description:  description,
      ).catchError((e) {
        debugPrint('[ReportService] Community notify failed (non-fatal): $e');
      });

      // 5b. Schedule finalize_report_validation() RPC in 30 minutes
      CommunityVoteService.instance.scheduleFinalization(reportId);
    }

    return report;
  }

  // ── Get Nearby Reports (PostGIS RPC + Pagination) ─────────────────────────
  Future<List<ReportModel>> getNearbyReports({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    int page     = 0,
    int pageSize = 50,
  }) async {
    try {
      final response = await _client.rpc(
        'get_nearby_reports',
        params: {
          'user_lat':    latitude,
          'user_lng':    longitude,
          'radius_m':    radiusKm * 1000,   // km → metres for ST_DWithin
          'page_limit':  pageSize,
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
      // Cancel any pending community vote finalization timer first
      CommunityVoteService.instance.cancelFinalization(reportId);
      await _client.from('reports').delete().eq('id', reportId);
    } catch (e) {
      rethrow;
    }
  }
}