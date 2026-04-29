import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staysafe/view/widgets/app_bar.dart';
import 'package:image_picker/image_picker.dart';
import '../../../Controller/report_controller.dart';
import '../../widgets/map_location_popup.dart';
import '../../../utils/app_colors.dart';
import '../../widgets/buttons.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportController>(
      builder: (context, controller, _) {
        final colorScheme = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        if (controller.isSubmitted) {
          // Success Screen
          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF0F1F1A) : Colors.green[50],
            body: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColor.getContainerBackground(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.green[800]! : Colors.green[200]!,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: AppColor.getPrimaryGradient(context),
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Report Submitted!",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.teal[300] : Colors.teal[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Thank you for contributing to community safety. "
                      "Your anonymous report has been added to the map.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColor.getTextPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: CustomButton(
                        text: "Report Another Incident",
                        textColor: Colors.white,
                        buttonColor: AppColor.getInteractivePrimary(context),
                        fontSize: 16,
                        onPressed: controller.resetSubmission,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        // Main Form Screen
        return Scaffold(
          appBar: AppMainBar(showBack: true),
          backgroundColor: colorScheme.surface,
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: AppColor.getPrimaryGradient(context),
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Report an Incident",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColor.getTextPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Help keep our community safe",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColor.getTextSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColor.teal900.withValues(alpha: 0.3)
                        : AppColor.teal50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? AppColor.teal700.withValues(alpha: 0.3)
                          : AppColor.teal100,
                    ),
                  ),
                  child: Text(
                    "🔒 Your report is completely anonymous. We don't collect personal information.",
                    style: TextStyle(
                      color: isDark ? AppColor.teal300 : AppColor.teal700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Incident Type
                Text(
                  "What happened?",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColor.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                Column(
                  children: [
                    _buildRadioCard(
                      context,
                      label: "Street Harassment",
                      value: "harassment",
                      groupValue: controller.incidentType,
                      onChanged: controller.setIncidentType,
                    ),
                    _buildRadioCard(
                      context,
                      label: "Theft / Snatching",
                      value: "theft",
                      groupValue: controller.incidentType,
                      onChanged: controller.setIncidentType,
                    ),
                    _buildRadioCard(
                      context,
                      label: "Criminal Activity",
                      value: "crime",
                      groupValue: controller.incidentType,
                      onChanged: controller.setIncidentType,
                    ),
                    _buildRadioCard(
                      context,
                      label: "Stalking / Following",
                      value: "stalking",
                      groupValue: controller.incidentType,
                      onChanged: controller.setIncidentType,
                    ),
                    _buildRadioCard(
                      context,
                      label: "Other Safety Concern",
                      value: "other",
                      groupValue: controller.incidentType,
                      onChanged: controller.setIncidentType,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Severity Level
                Text(
                  "How serious was it?",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColor.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                Column(
                  children: [
                    _buildSeverityCard(
                      context,
                      title: "HIGH RISK",
                      subtitle: "Immediate danger",
                      badgeColor: AppColor.dangerRed,
                      value: "high",
                      groupValue: controller.severity,
                      onChanged: controller.setSeverity,
                    ),
                    _buildSeverityCard(
                      context,
                      title: "MEDIUM RISK",
                      subtitle: "Concerning situation",
                      badgeColor: AppColor.alertOrange,
                      value: "medium",
                      groupValue: controller.severity,
                      onChanged: controller.setSeverity,
                    ),
                    _buildSeverityCard(
                      context,
                      title: "LOW RISK",
                      subtitle: "Minor incident",
                      badgeColor: AppColor.warningAmber,
                      value: "low",
                      groupValue: controller.severity,
                      onChanged: controller.setSeverity,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Location Input
                Text(
                  "Where did this happen?",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColor.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller.locationController,
                        style: TextStyle(color: AppColor.getTextPrimary(context)),
                        decoration: InputDecoration(
                          hintText: "Enter location manually",
                          hintStyle: TextStyle(color: AppColor.getTextTertiary(context)),
                          filled: true,
                          fillColor: AppColor.getContainerBackground(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppColor.getContainerBorder(context)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppColor.getContainerBorder(context)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppColor.getInteractivePrimary(context)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final result = await showDialog<Map<String, dynamic>>(
                          context: context,
                          builder: (_) => const MapLocationPopup(),
                        );
                        if (result != null) {
                          controller.setSelectedLocation(
                            latLng: result["latLng"],
                            address: result["address"],
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.getContainerBackground(context),
                        foregroundColor: AppColor.getInteractivePrimary(context),
                        side: BorderSide(color: AppColor.getInteractivePrimary(context)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        minimumSize: const Size(46, 46),
                      ),
                      child: const Icon(Icons.location_pin),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "💡 Or use current location (automatically detected)",
                  style: TextStyle(fontSize: 12, color: AppColor.getTextSecondary(context)),
                ),
                const SizedBox(height: 16),

                // Time
                Text(
                  "When did this happen?",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColor.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Date",
                  style: TextStyle(
                    fontSize: 14, 
                    fontWeight: FontWeight.bold,
                    color: AppColor.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller.dateController,
                  readOnly: true,
                  style: TextStyle(color: AppColor.getTextPrimary(context)),
                  decoration: InputDecoration(
                    hintText: "Select Date",
                    hintStyle: TextStyle(color: AppColor.getTextTertiary(context)),
                    filled: true,
                    fillColor: AppColor.getContainerBackground(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColor.getContainerBorder(context)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColor.getContainerBorder(context)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    suffixIcon: Icon(Icons.calendar_today, color: AppColor.getIconPrimary(context)),
                  ),
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );

                    if (picked != null) {
                      controller.dateController.text =
                          "${picked.day}-${picked.month}-${picked.year}";
                    }
                  },
                ),

                const SizedBox(height: 16),
                Text(
                  "Time",
                  style: TextStyle(
                    fontSize: 14, 
                    fontWeight: FontWeight.bold,
                    color: AppColor.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller.timeController,
                  readOnly: true,
                  style: TextStyle(color: AppColor.getTextPrimary(context)),
                  decoration: InputDecoration(
                    hintText: "Select Time",
                    hintStyle: TextStyle(color: AppColor.getTextTertiary(context)),
                    filled: true,
                    fillColor: AppColor.getContainerBackground(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColor.getContainerBorder(context)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColor.getContainerBorder(context)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    suffixIcon: Icon(Icons.access_time, color: AppColor.getIconPrimary(context)),
                  ),
                  onTap: () async {
                    TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );

                    if (pickedTime != null) {
                      controller.timeController.text = pickedTime.format(
                        context,
                      );
                    }
                  },
                ),

                const SizedBox(height: 16),
                // Description
                Text(
                  "Additional Details (Optional)",
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold,
                    color: AppColor.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller.descriptionController,
                  maxLines: 5,
                  style: TextStyle(color: AppColor.getTextPrimary(context)),
                  decoration: InputDecoration(
                    hintText:
                        "Provide any additional details that might help others stay safe...",
                    hintStyle: TextStyle(color: AppColor.getTextTertiary(context)),
                    filled: true,
                    fillColor: AppColor.getContainerBackground(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColor.getContainerBorder(context)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColor.getContainerBorder(context)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColor.getInteractivePrimary(context)),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "🔒 No personal information will be shared",
                  style: TextStyle(fontSize: 12, color: AppColor.getTextSecondary(context)),
                ),
                const SizedBox(height: 16),

                // Photo Upload
                Text(
                  "Add Photo (Optional)",
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold,
                    color: AppColor.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),

                // Show image preview if selected
                if (controller.selectedImage != null)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          controller.selectedImage!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: controller.removeImage,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 8),

                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    FocusScope.of(context).unfocus(); // 🔑 important
                    _showImagePickerBottomSheet(context, controller);
                  },
                  child: Container(
                    width: double.infinity,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColor.getContainerBackground(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColor.getInteractivePrimary(context),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, color: AppColor.getInteractivePrimary(context)),
                        const SizedBox(width: 8),
                        Text(
                          controller.selectedImage == null
                              ? "Upload Photo"
                              : "Change Photo",
                          style: TextStyle(
                            color: AppColor.getInteractivePrimary(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 4),
                Text(
                  "📸 Images are reviewed before being shared",
                  style: TextStyle(fontSize: 12, color: AppColor.getTextSecondary(context)),
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: CustomButton(
                    text: "Submit Anonymous Report",
                    textColor: Colors.white,
                    buttonColor: AppColor.getInteractivePrimary(context),
                    fontSize: 16,
                    onPressed: controller.handleSubmit,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------- Helper Widgets ----------------
  void _showImagePickerBottomSheet(
    BuildContext context,
    ReportController controller,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: AppColor.getContainerBackground(context),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: AppColor.getIconPrimary(context)),
                title: Text("Take photo", style: TextStyle(color: AppColor.getTextPrimary(context))),
                onTap: () {
                  Navigator.pop(context);
                  controller.pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: AppColor.getIconPrimary(context)),
                title: Text("Choose from gallery", style: TextStyle(color: AppColor.getTextPrimary(context))),
                onTap: () {
                  Navigator.pop(context);
                  controller.pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRadioCard(
    BuildContext context, {
    required String label,
    required String value,
    required String groupValue,
    required Function(String) onChanged,
  }) {
    final isSelected = value == groupValue;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColor.getInteractivePrimary(context).withValues(alpha: isDark ? 0.2 : 0.1)
              : AppColor.getContainerBackground(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColor.getInteractivePrimary(context) : AppColor.getContainerBorder(context),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: (val) => onChanged(val!),
              activeColor: AppColor.getInteractivePrimary(context),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14, 
                fontWeight: FontWeight.w600,
                color: AppColor.getTextPrimary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color badgeColor,
    required String value,
    required String groupValue,
    required Function(String) onChanged,
  }) {
    final isSelected = value == groupValue;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColor.getInteractivePrimary(context).withValues(alpha: isDark ? 0.2 : 0.1)
              : AppColor.getContainerBackground(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColor.getInteractivePrimary(context) : AppColor.getContainerBorder(context),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: (val) => onChanged(val!),
              activeColor: AppColor.getInteractivePrimary(context),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14, 
                  color: AppColor.getTextSecondary(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
