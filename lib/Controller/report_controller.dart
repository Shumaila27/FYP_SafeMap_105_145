// lib/Controller/report_controller.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../services/report_service.dart';

class ReportController extends ChangeNotifier {
  // ── Form State ─────────────────────────────────────────────────────────────

  /// Selected category name (matches report_categories.name in DB)
  /// e.g. "harassment", "theft", "crime", "stalking", "other"
  String? categoryId;

  /// Severity level — default medium
  String severity = 'medium';

  /// Text controllers
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();

  /// FIX: Store real DateTime/TimeOfDay objects so we can combine them
  /// for the incident_time TIMESTAMPTZ column in Supabase
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  /// Coordinates from map popup
  LatLng? selectedLatLng;

  /// Optional photo
  File? selectedImage;

  bool isLoading = false;
  bool isSubmitted = false;
  String? errorMessage;

  final _service = ReportService();
  final _picker = ImagePicker();

  // ── Date / Time Setters ────────────────────────────────────────────────────

  /// FIX: Stores the real DateTime AND updates the display text field.
  /// Previously the screen was writing directly to dateController.text,
  /// meaning the actual DateTime was never stored.
  void setDate(DateTime date) {
    selectedDate = date;
    dateController.text = '${date.day}-${date.month}-${date.year}';
    notifyListeners();
  }

  /// FIX: Stores the real TimeOfDay AND updates the display text field.
  /// [formattedTime] is passed from the screen because TimeOfDay.format()
  /// needs a BuildContext that the controller must not hold.
  void setTime(TimeOfDay time, String formattedTime) {
    selectedTime = time;
    timeController.text = formattedTime;
    notifyListeners();
  }

  /// FIX: Combines selectedDate + selectedTime into a single DateTime
  /// for the incident_time column. Falls back to DateTime.now() if not picked.
  DateTime get incidentTime {
    if (selectedDate == null) return DateTime.now();
    final t = selectedTime ?? TimeOfDay.now();
    return DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      t.hour,
      t.minute,
    );
  }

  // ── Setters ────────────────────────────────────────────────────────────────

  void setCategory(String value) {
    categoryId = value;
    _clearError();
    notifyListeners();
  }

  void setSeverity(String value) {
    severity = value;
    notifyListeners();
  }

  void setSelectedLocation({
    required LatLng latLng,
    required String address,
  }) {
    selectedLatLng = latLng;
    locationController.text = address;
    _clearError();
    notifyListeners();
  }

  // ── Image Handling ─────────────────────────────────────────────────────────

  /// FIX: Added 5 MB size check before accepting the image.
  /// Previously any size was accepted, which could cause large upload failures.
  static const int _maxImageBytes = 5 * 1024 * 1024; // 5 MB

  Future<void> pickImage(ImageSource source) async {
    final XFile? picked =
    await _picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;

    final file = File(picked.path);
    final size = await file.length();

    if (size > _maxImageBytes) {
      errorMessage =
      'Image is too large (${(size / 1024 / 1024).toStringAsFixed(1)} MB). '
          'Please choose a photo smaller than 5 MB.';
      notifyListeners();
      return;
    }

    selectedImage = file;
    _clearError();
    notifyListeners();
  }

  void removeImage() {
    selectedImage = null;
    notifyListeners();
  }

  // ── Validation ─────────────────────────────────────────────────────────────

  /// FIX: Added location validation alongside category validation.
  /// Previously only category was checked.
  String? _validate() {
    if (categoryId == null || categoryId!.isEmpty) {
      return 'Please select what type of incident occurred.';
    }
    if (selectedLatLng == null && locationController.text.trim().isEmpty) {
      return 'Please provide a location — tap the pin icon or type an address.';
    }
    return null;
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> handleSubmit() async {
    final error = _validate();
    if (error != null) {
      errorMessage = error;
      notifyListeners();
      return;
    }

    errorMessage = null;
    isLoading = true;
    notifyListeners();

    try {
      await _service.submitReport(
        categoryName: categoryId!,
        severity: severity,
        description: descriptionController.text.trim(),
        locationAddress: locationController.text.trim().isEmpty
            ? null
            : locationController.text.trim(),
        latitude: selectedLatLng?.latitude,
        longitude: selectedLatLng?.longitude,
        incidentTime: incidentTime, // FIX: now correctly passed to service
        imageFile: selectedImage,
        isAnonymous: true,
      );

      isLoading = false;
      isSubmitted = true;
      notifyListeners();

      // FIX: Specific catch blocks so UI shows actionable messages
      // instead of a generic "submission failed"
    } on ImageUploadException catch (e) {
      isLoading = false;
      errorMessage = e.message;
      notifyListeners();
    } on ReportSubmitException catch (e) {
      isLoading = false;
      errorMessage = e.message;
      notifyListeners();
    } catch (_) {
      isLoading = false;
      errorMessage =
      'Something went wrong. Please check your connection and try again.';
      notifyListeners();
    }
  }

  // ── Reset ──────────────────────────────────────────────────────────────────

  void resetSubmission() {
    isSubmitted = false;
    isLoading = false;
    errorMessage = null;
    categoryId = null;
    severity = 'medium';
    selectedLatLng = null;
    selectedImage = null;
    selectedDate = null; // FIX: reset new date/time state too
    selectedTime = null;
    descriptionController.clear();
    locationController.clear();
    dateController.clear();
    timeController.clear();
    notifyListeners();
  }

  void _clearError() {
    errorMessage = null;
  }

  // ── Dispose ────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    descriptionController.dispose();
    locationController.dispose();
    dateController.dispose();
    timeController.dispose();
    super.dispose();
  }
}