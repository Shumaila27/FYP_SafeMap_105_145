import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';


class ReportController extends ChangeNotifier {
  /// Incident Type (default = harassment)
  String incidentType = "harassment";

  /// Severity Level (default = medium)
  String severity = "medium";

  /// Description text field
  TextEditingController descriptionController = TextEditingController();

  /// Location text field (displayed on report screen)
  TextEditingController locationController = TextEditingController();

  /// Selected map coordinates (from popup)
  LatLng? selectedLatLng;

  /// Time & date input
  TextEditingController timeController = TextEditingController();
  TextEditingController dateController = TextEditingController();

  /// Submit state
  bool isSubmitted = false;

  /// Image picker
  final ImagePicker _picker = ImagePicker();

  /// Selected image file (optional)
  File? selectedImage;

  // ---------------- Incident Controls ----------------

  void setIncidentType(String value) {
    incidentType = value;
    notifyListeners();
  }

  void setSeverity(String value) {
    severity = value;
    notifyListeners();
  }

  // ---------------- Location Handling ----------------

  /// Called when user selects location from map popup
  void setSelectedLocation({
    required LatLng latLng,
    required String address,
  }) {
    selectedLatLng = latLng;
    locationController.text = address;
    notifyListeners();
  }

  // ---------------- Image Handling ----------------

  Future<void> pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (image != null) {
      selectedImage = File(image.path);
      notifyListeners();
    }
  }

  void removeImage() {
    selectedImage = null;
    notifyListeners();
  }

  // ---------------- Submit Handling ----------------


  void handleSubmit() {
    isSubmitted = true;
    notifyListeners();

    Future.delayed(const Duration(seconds: 3), () {
      isSubmitted = false;

      descriptionController.clear();
      locationController.clear();
      timeController.clear();
      dateController.clear();
      selectedImage = null;
      selectedLatLng = null;

      notifyListeners();
    });
  }

  void resetSubmission() {
    isSubmitted = false;
    notifyListeners();
  }

  @override
  void dispose() {
    descriptionController.dispose();
    locationController.dispose();
    timeController.dispose();
    dateController.dispose();
    super.dispose();
  }
}