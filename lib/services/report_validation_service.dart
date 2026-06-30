// lib/services/report_validation_service.dart
//
// ──────────────────────────────────────────────────────────────
//  ReportValidationService  (Method 1 — AI Analysis)
//
//  Uses Gemini 2.0 Flash via the Generative Language REST API to
//  perform multimodal validation of a submitted incident report
//  BEFORE it is saved to Supabase.
//
//  Checks performed:
//  1. Does the image match the description?
//  2. Is the location consistent with the incident category?
//  3. Is the date/time realistic?
//  4. Is the description sufficiently detailed?
//
//  Returns AiValidationResult { aiScore, verdict, reason }
//
//  SETUP: Add  GEMINI_API_KEY=your_key  to your .env file.
// ──────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

// ── Result Model ──────────────────────────────────────────────────────────────

class AiValidationResult {
  /// AI credibility score — 0 (likely fake) to 100 (clearly credible).
  final int aiScore;

  /// One of: 'credible' | 'suspicious' | 'fake'
  final String verdict;

  /// One-sentence reason the model assigned this score.
  final String reason;

  const AiValidationResult({
    required this.aiScore,
    required this.verdict,
    required this.reason,
  });

  factory AiValidationResult.fromJson(Map<String, dynamic> json) {
    return AiValidationResult(
      aiScore: (json['ai_score'] as num?)?.toInt().clamp(0, 100) ?? 50,
      verdict: json['verdict'] as String? ?? 'suspicious',
      reason:  json['reason']  as String? ?? 'No reason provided.',
    );
  }

  /// Neutral fallback used when the API is unreachable or the key is missing.
  /// Gives 50 so the community vote still has meaningful weight.
  factory AiValidationResult.neutral() => const AiValidationResult(
    aiScore: 50,
    verdict: 'suspicious',
    reason:  'AI validation unavailable — report queued for manual review.',
  );

  @override
  String toString() =>
      'AiValidationResult(score: $aiScore, verdict: $verdict)';
}

// ── Service ───────────────────────────────────────────────────────────────────

class ReportValidationService {
  ReportValidationService._();
  static final ReportValidationService instance = ReportValidationService._();

  // Gemini 2.0 Flash REST endpoint
  static const String _model   = 'gemini-2.0-flash';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  String? get _apiKey => dotenv.env['GEMINI_API_KEY'];

  // ════════════════════════════════════════════════════════════════════════════
  //  PUBLIC — analyseReport
  // ════════════════════════════════════════════════════════════════════════════

  /// Calls Gemini 2.0 Flash with all available report fields and
  /// returns an [AiValidationResult].
  ///
  /// - If [imageFile] is provided it is encoded as base64 inline data
  ///   so the model can visually check whether the image matches.
  /// - On any network/API error a neutral score (50) is returned so the
  ///   submission still proceeds — community votes can compensate later.
  Future<AiValidationResult> analyseReport({
    required String   categoryName,
    required String   description,
    String?           locationAddress,
    DateTime?         incidentTime,
    File?             imageFile,
  }) async {
    final key = _apiKey;
    if (key == null || key.isEmpty) {
      debugPrint('[AIValidation] GEMINI_API_KEY not set — returning neutral.');
      return AiValidationResult.neutral();
    }

    try {
      // 1. Build the multimodal parts list
      final List<Map<String, dynamic>> parts = [];

      // Always include the text prompt first
      parts.add({
        'text': _buildPrompt(
          categoryName:    categoryName,
          description:     description,
          locationAddress: locationAddress,
          incidentTime:    incidentTime,
          hasImage:        imageFile != null,
        ),
      });

      // Optionally include the image as base64 inline data
      if (imageFile != null) {
        final bytes       = await imageFile.readAsBytes();
        final base64Image = base64Encode(bytes);
        parts.add({
          'inline_data': {
            'mime_type': _mimeType(imageFile.path),
            'data':      base64Image,
          },
        });
      }

      // 2. Assemble the request body
      final body = json.encode({
        'contents': [
          {'parts': parts},
        ],
        'generationConfig': {
          'responseMimeType': 'application/json', // model returns JSON directly
          'temperature':       0.1,                // low = deterministic scoring
          'maxOutputTokens':   256,
        },
      });

      // 3. POST to Gemini REST API
      final url = Uri.parse('$_baseUrl?key=$key');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 30));

      debugPrint('[AIValidation] HTTP status: ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint('[AIValidation] Error body: ${response.body}');
        return AiValidationResult.neutral();
      }

      // 4. Unwrap the Gemini response envelope
      final envelope  = json.decode(response.body) as Map<String, dynamic>;
      final candidates = envelope['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        debugPrint('[AIValidation] Empty candidates list.');
        return AiValidationResult.neutral();
      }

      final content  = candidates[0]['content'] as Map<String, dynamic>?;
      final textParts = (content?['parts'] as List<dynamic>?)
          ?.map((p) => p['text'] as String?)
          .where((t) => t != null && t.isNotEmpty)
          .toList();

      if (textParts == null || textParts.isEmpty) {
        debugPrint('[AIValidation] No text in response.');
        return AiValidationResult.neutral();
      }

      final rawText = textParts.first!;
      debugPrint('[AIValidation] Raw AI response: $rawText');

      // 5. Decode the inner JSON the model returned
      final aiJson = json.decode(rawText) as Map<String, dynamic>;
      return AiValidationResult.fromJson(aiJson);

    } on TimeoutException {
      debugPrint('[AIValidation] Request timed out — returning neutral.');
      return AiValidationResult.neutral();
    } catch (e) {
      debugPrint('[AIValidation] Exception: $e');
      return AiValidationResult.neutral();
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ════════════════════════════════════════════════════════════════════════════

  String _buildPrompt({
    required String   categoryName,
    required String   description,
    String?           locationAddress,
    DateTime?         incidentTime,
    required bool     hasImage,
  }) {
    final timeStr = incidentTime != null
        ? '${incidentTime.year}-'
          '${incidentTime.month.toString().padLeft(2, '0')}-'
          '${incidentTime.day.toString().padLeft(2, '0')} '
          '${incidentTime.hour.toString().padLeft(2, '0')}:'
          '${incidentTime.minute.toString().padLeft(2, '0')}'
        : 'Not specified';

    return '''
You are a safety report validation system for a community safety app called StaySafe.
Your job is to score the credibility of user-submitted incident reports.

REPORT DETAILS:
- Category  : $categoryName
- Description: ${description.trim().isEmpty ? 'Not provided' : description.trim()}
- Location  : ${locationAddress ?? 'Not specified'}
- Date & Time: $timeStr
${hasImage ? '- Image: Attached below — analyse it carefully.' : '- Image: Not provided.'}

EVALUATION CRITERIA (score each and produce a single combined score):

1. IMAGE MATCH (only when image is provided):
   - Does the image visually match the incident category and description?
   - Red flags: selfies, unrelated scenes, blank/black images, stock photos.
   - No image → treat this criterion as neutral.

2. LOCATION CONSISTENCY:
   - Is the reported location type plausible for this incident category?
   - Examples of plausible: street theft in a commercial area, harassment at a bus stop.
   - Examples of implausible: murder inside a residential kitchen claimed as a public assault.

3. TIME REALISM:
   - Future timestamps → strong negative signal.
   - Incident time > 30 days old with no context → mild negative signal.
   - Night-time timings for outdoor incidents are normal.

4. DESCRIPTION QUALITY:
   - Is the description informative and specific?
   - Obvious test data (e.g. "aaa", "test report", "xxx") → score near 0.
   - Single-word descriptions without context → mild negative.
   - Detailed, coherent descriptions → positive signal.

RESPOND ONLY with valid JSON — no markdown, no backticks, no extra text:
{
  "ai_score": <integer 0–100>,
  "verdict": "<one of: credible | suspicious | fake>",
  "reason": "<one plain-English sentence, max 120 characters>"
}

Scoring guide:
  80–100 → Credible: report is detailed, image matches, time/location are plausible.
  50–79  → Suspicious: some concerns but could be genuine.
  0–49   → Fake: test data, image mismatch, or clearly fabricated content.
''';
  }

  /// Infers an image MIME type from the file extension.
  String _mimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':  return 'image/png';
      case 'webp': return 'image/webp';
      case 'gif':  return 'image/gif';
      default:     return 'image/jpeg';
    }
  }
}
