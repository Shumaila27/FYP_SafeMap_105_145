// profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:staysafe/view/widgets/app_bar.dart';
import '../../utils/app_colors.dart';
import 'help_support_new.dart';
import 'settings_screen.dart';
import 'about_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Profile picture state
  File? _profileImage;
  String _userName = 'Shumaila Wakeel';
  String _userEmail = 'shumaila.wakeel@example.com';

  // Controllers for editing
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  // Emergency contacts state
  final List<Map<String, String>> _emergencyContacts = [
    {'name': 'Ayesha Khan', 'phone': '+92 300 1234567', 'initials': 'AK'},
    {'name': 'Fatima Ali', 'phone': '+92 333 9876543', 'initials': 'FA'},
  ];

  // Controllers for emergency contact editing
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();

  // switches (defaultChecked in React)
  bool anonymousReporting = true;
  bool locationServices = true;
  bool voiceCommands = true;

  bool safetyAlerts = true;
  bool aiRecommendations = true;
  bool communityUpdates = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _userName);
    _emailController = TextEditingController(text: _userEmail);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  // Image picker methods
  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImagePickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Update Profile Picture',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppColor.appSecondary),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppColor.appSecondary),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_profileImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Photo'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _profileImage = null;
                  });
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    print('Edit profile dialog called!');
    _nameController.text = _userName;
    _emailController.text = _userEmail;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _userName = _nameController.text;
                _userEmail = _emailController.text;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile updated successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.appSecondary,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEmergencyContactsDialog() {
    // Capture the main context for SnackBar
    final mainContext = context;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Emergency Contacts'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400, // Set a fixed height
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Add new contact form
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Add New Contact',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _contactNameController,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _contactPhoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (_contactNameController.text.isNotEmpty &&
                                _contactPhoneController.text.isNotEmpty) {
                              setState(() {
                                _emergencyContacts.add({
                                  'name': _contactNameController.text,
                                  'phone': _contactPhoneController.text,
                                  'initials': _contactNameController.text
                                      .split(' ')
                                      .map((n) => n[0])
                                      .take(2)
                                      .join()
                                      .toUpperCase(),
                                });
                              });
                              setDialogState(() {});
                              _contactNameController.clear();
                              _contactPhoneController.clear();
                              ScaffoldMessenger.of(mainContext).showSnackBar(
                                const SnackBar(
                                  content: Text('Contact added successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColor.appSecondary,
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: const Text('Add Contact'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Existing contacts list
                  const Text(
                    'Existing Contacts',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._emergencyContacts.asMap().entries.map((entry) {
                    int index = entry.key;
                    Map<String, String> contact = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  index == 0
                                      ? const Color(0xFF3B82F6)
                                      : const Color(0xFFF472B6),
                                  index == 0
                                      ? const Color(0xFF06B6D4)
                                      : const Color(0xFFFB7185),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                contact['initials']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  contact['name']!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  contact['phone']!,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () {
                                  _contactNameController.text =
                                      contact['name']!;
                                  _contactPhoneController.text =
                                      contact['phone']!;
                                  _showEditContactDialog(index, setDialogState);
                                },
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _emergencyContacts.removeAt(index);
                                  });
                                  setDialogState(() {});
                                  ScaffoldMessenger.of(
                                    mainContext,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text('Contact removed'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditContactDialog(int index, StateSetter setDialogState) {
    // Capture the main context for SnackBar
    final mainContext = context;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _contactNameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contactPhoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_contactNameController.text.isNotEmpty &&
                  _contactPhoneController.text.isNotEmpty) {
                setState(() {
                  _emergencyContacts[index] = {
                    'name': _contactNameController.text,
                    'phone': _contactPhoneController.text,
                    'initials': _contactNameController.text
                        .split(' ')
                        .map((n) => n[0])
                        .take(2)
                        .join()
                        .toUpperCase(),
                  };
                });
                setDialogState(() {});
                _contactNameController.clear();
                _contactPhoneController.clear();
                Navigator.pop(context);
                ScaffoldMessenger.of(mainContext).showSnackBar(
                  const SnackBar(
                    content: Text('Contact updated successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.appSecondary,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // center content with max width similar to max-w-2xl
    return Scaffold(
      appBar: AppMainBar(showBack: true),
      backgroundColor: Theme.of(context).colorScheme.surface, // bg-background
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Header Card
                    ProfileHeader(
                      profileImage: _profileImage,
                      userName: _userName,
                      userEmail: _userEmail,
                      onImageTap: _showImagePickerBottomSheet,
                      onEditTap: _showEditProfileDialog,
                    ),

                    const SizedBox(height: 15),

                    // Stats Cards row
                    StatsCards(),

                    const SizedBox(height: 15),

                    ContributionBadgeSection(),

                    const SizedBox(height: 15),

                    EmergencyContactsSection(
                      emergencyContacts: _emergencyContacts,
                      onEditContacts: _showEmergencyContactsDialog,
                    ),

                    const SizedBox(height: 15),

                    PrivacySettingsSection(
                      anonymousReporting: anonymousReporting,
                      locationServices: locationServices,
                      voiceCommands: voiceCommands,
                      onAnonymousChanged: (v) =>
                          setState(() => anonymousReporting = v),
                      onLocationChanged: (v) =>
                          setState(() => locationServices = v),
                      onVoiceChanged: (v) => setState(() => voiceCommands = v),
                    ),

                    const SizedBox(height: 18),

                    NotificationsSettingsSection(
                      safetyAlerts: safetyAlerts,
                      aiRecommendations: aiRecommendations,
                      communityUpdates: communityUpdates,
                      onSafetyAlertsChanged: (v) =>
                          setState(() => safetyAlerts = v),
                      onAiRecommendationsChanged: (v) =>
                          setState(() => aiRecommendations = v),
                      onCommunityUpdatesChanged: (v) =>
                          setState(() => communityUpdates = v),
                    ),

                    const SizedBox(height: 18),

                    MenuOptionsSection(),

                    const SizedBox(height: 18),

                    LogoutButtonSection(
                      onLogout: () {
                        // placeholder - user will implement navigation/logout
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Logged out (placeholder)'),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // App Info
                    Column(
                      children: const [
                        Text(
                          'SafeMap v1.0.0',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Making Pakistan safer for everyone',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ---------------------------
   ProfileHeader (card)
   --------------------------- */
class ProfileHeader extends StatelessWidget {
  final File? profileImage;
  final String userName;
  final String userEmail;
  final VoidCallback onImageTap;
  final VoidCallback onEditTap;

  const ProfileHeader({
    super.key,
    this.profileImage,
    required this.userName,
    required this.userEmail,
    required this.onImageTap,
    required this.onEditTap,
  });

  // small helper for card decoration used across cards to keep look consistent
  BoxDecoration _cardDecoration({
    required Gradient? gradient,
    required Color borderColor,
  }) {
    return BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: borderColor, width: 1.6),
      boxShadow: const [
        BoxShadow(
          color: Color.fromRGBO(0, 0, 0, 0.06),
          blurRadius: 10,
          offset: Offset(0, 6),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _cardDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF3E8FF), Color(0xFFFCE8F8), Color(0xFFFFE6F0)],
        ),
        borderColor: const Color(0xFFE9D8FF),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile Picture with edit capability
          GestureDetector(
            onTap: onImageTap,
            child: Stack(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white, width: 4),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColor.appSecondary, AppColor.appPrimary],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.12),
                        blurRadius: 10,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: profileImage != null
                        ? Image.file(
                            profileImage!,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColor.appSecondary,
                                  AppColor.appPrimary,
                                ],
                              ),
                            ),
                            child: Center(
                              child: Text(
                                userName.isNotEmpty
                                    ? userName
                                          .split(' ')
                                          .map((n) => n[0])
                                          .take(2)
                                          .join()
                                          .toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                // Camera icon overlay
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColor.appSecondary,
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: AppColor.appSecondary,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                    // Edit button
                    GestureDetector(
                      onTap: () {
                        print('Edit button tapped!');
                        onEditTap();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColor.appSecondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.edit,
                          color: AppColor.appSecondary,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Member since Jan 2025',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: const [
                    BadgeWidget(
                      text: 'Verified',
                      filled: true,
                      gradientFrom: Color(0xFF6D28D9),
                      gradientTo: Color(0xFFDB2777),
                    ),
                    SizedBox(width: 8),
                    BadgeWidget(
                      text: 'Active Guardian',
                      filled: false,
                      borderColor: Color(0xFFE9D8FF),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------------------------
   StatsCards (grid of 3)
   --------------------------- */
class StatsCards extends StatelessWidget {
  const StatsCards({super.key});

  Widget _buildStat({
    required Widget icon,
    required String value,
    required String label,
    required Gradient gradient,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6E6F0), width: 1.4),
      ),
      child: Column(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.08),
                  blurRadius: 8,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Center(child: icon),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // use Row with expanded children to mimic 3-grid
    return Row(
      children: [
        Expanded(
          child: _buildStat(
            icon: const Icon(LucideIcons.shield, size: 22, color: Colors.white),
            value: '23',
            label: 'Safe Walks',
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
            ),
            valueColor: const Color(0xFF6D28D9),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStat(
            icon: const Icon(LucideIcons.mapPin, size: 22, color: Colors.white),
            value: '5',
            label: 'Reports',
            gradient: const LinearGradient(
              colors: [Color(0xFFF97316), Color(0xFFF43F5E)],
            ),
            valueColor: const Color(0xFFFB923C),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStat(
            icon: const Icon(LucideIcons.award, size: 22, color: Colors.white),
            value: '85',
            label: 'Safety Points',
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
            ),
            valueColor: const Color(0xFF10B981),
          ),
        ),
      ],
    );
  }
}

/* ---------------------------
   ContributionBadgeSection
   --------------------------- */
class ContributionBadgeSection extends StatelessWidget {
  const ContributionBadgeSection({super.key});

  BoxDecoration get _decoration => BoxDecoration(
    gradient: const LinearGradient(
      colors: [Color(0xFFFFF7ED), Color(0xFFFFF1CC)],
    ),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: const Color(0xFFFDE68A), width: 1.6),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _decoration,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFFCD34D)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.08),
                  blurRadius: 8,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: const Center(
              child: Icon(LucideIcons.award, color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Safety Champion',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "You've helped make the community safer!",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF92400E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------------------------
   EmergencyContactsSection
   --------------------------- */
class EmergencyContactsSection extends StatelessWidget {
  final List<Map<String, String>> emergencyContacts;
  final VoidCallback onEditContacts;

  const EmergencyContactsSection({
    super.key,
    required this.emergencyContacts,
    required this.onEditContacts,
  });

  Widget _contactTile(
    String initials,
    String name,
    String phone,
    Color from,
    Color to,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9E9F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [from, to]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF3F4F6), width: 2),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  phone,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6E6F0), width: 1.4),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(LucideIcons.users, color: Color(0xFF6D28D9), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Emergency Contacts',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: onEditContacts,
                icon: const Icon(Icons.edit, color: Color(0xFF6D28D9)),
                label: Row(
                  children: const [
                    Text(
                      'Edit',
                      style: TextStyle(
                        color: Color(0xFF6D28D9),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      LucideIcons.chevronRight,
                      color: Color(0xFF6D28D9),
                      size: 16,
                    ),
                  ],
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: emergencyContacts.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, String> contact = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _contactTile(
                  contact['initials']!,
                  contact['name']!,
                  contact['phone']!,
                  index == 0
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFFF472B6),
                  index == 0
                      ? const Color(0xFF06B6D4)
                      : const Color(0xFFFB7185),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/* ---------------------------
   PrivacySettingsSection
   --------------------------- */
class PrivacySettingsSection extends StatelessWidget {
  final bool anonymousReporting;
  final bool locationServices;
  final bool voiceCommands;
  final ValueChanged<bool> onAnonymousChanged;
  final ValueChanged<bool> onLocationChanged;
  final ValueChanged<bool> onVoiceChanged;

  const PrivacySettingsSection({
    super.key,
    required this.anonymousReporting,
    required this.locationServices,
    required this.voiceCommands,
    required this.onAnonymousChanged,
    required this.onLocationChanged,
    required this.onVoiceChanged,
  });

  Widget _settingTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale:
                0.7, // change this value to make the switch smaller or bigger
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColor.appSecondary, // or your color
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6E6F0), width: 1.4),
      ),
      child: Column(
        children: [
          Row(
            children: const [
              Icon(LucideIcons.shield, color: Color(0xFF6D28D9)),
              SizedBox(width: 8),
              Text(
                'Privacy & Safety',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              _settingTile(
                title: 'Anonymous Reporting',
                subtitle: 'Keep your identity private',
                value: anonymousReporting,
                onChanged: onAnonymousChanged,
              ),
              const SizedBox(height: 8),
              _settingTile(
                title: 'Location Services',
                subtitle: 'For accurate safety scores',
                value: locationServices,
                onChanged: onLocationChanged,
              ),
              const SizedBox(height: 8),
              _settingTile(
                title: 'Voice Commands',
                subtitle: 'Hands-free panic button',
                value: voiceCommands,
                onChanged: onVoiceChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/* ---------------------------
   NotificationsSettingsSection
   --------------------------- */
class NotificationsSettingsSection extends StatelessWidget {
  final bool safetyAlerts;
  final bool aiRecommendations;
  final bool communityUpdates;
  final ValueChanged<bool> onSafetyAlertsChanged;
  final ValueChanged<bool> onAiRecommendationsChanged;
  final ValueChanged<bool> onCommunityUpdatesChanged;

  const NotificationsSettingsSection({
    super.key,
    required this.safetyAlerts,
    required this.aiRecommendations,
    required this.communityUpdates,
    required this.onSafetyAlertsChanged,
    required this.onAiRecommendationsChanged,
    required this.onCommunityUpdatesChanged,
  });

  Widget _notificationTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale:
                0.8, // change this value to make the switch smaller or bigger
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColor.appSecondary, // or your color
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6E6F0), width: 1.4),
      ),
      child: Column(
        children: [
          Row(
            children: const [
              Icon(LucideIcons.bell, color: Color(0xFF6D28D9)),
              SizedBox(width: 8),
              Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              _notificationTile(
                title: 'Safety Alerts',
                subtitle: 'High-risk area warnings',
                value: safetyAlerts,
                onChanged: onSafetyAlertsChanged,
              ),
              const SizedBox(height: 8),
              _notificationTile(
                title: 'AI Recommendations',
                subtitle: 'Route suggestions',
                value: aiRecommendations,
                onChanged: onAiRecommendationsChanged,
              ),
              const SizedBox(height: 8),
              _notificationTile(
                title: 'Community Updates',
                subtitle: 'New reports nearby',
                value: communityUpdates,
                onChanged: onCommunityUpdatesChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/* ---------------------------
   MenuOptionsSection
   --------------------------- */
class MenuOptionsSection extends StatelessWidget {
  const MenuOptionsSection({super.key});

  Widget _menuButton({
    required Widget leading,
    required String title,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      height: 50,
      child: TextButton(
        onPressed: onTap ?? () {},
        style: TextButton.styleFrom(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: leading),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _menuButton(
          leading: const Icon(LucideIcons.settings, color: Color(0xFF374151)),
          title: 'Settings',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
        const SizedBox(height: 8),
        _menuButton(
          leading: const Icon(LucideIcons.info, color: Color(0xFF374151)),
          title: 'About',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AboutScreen()),
            );
          },
        ),
        const SizedBox(height: 8),
        const SizedBox(height: 8),
        _menuButton(
          leading: const Icon(Icons.help, color: Color(0xFF374151)),
          title: 'Help & Support',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HelpSupportScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}

/* ---------------------------
   LogoutButtonSection
   --------------------------- */
class LogoutButtonSection extends StatelessWidget {
  final VoidCallback onLogout;
  const LogoutButtonSection({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: OutlinedButton.icon(
        onPressed: onLogout,
        icon: const Icon(LucideIcons.logOut, color: Color(0xFFDC2626)),
        label: const Text(
          'Logout',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFDC2626),
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }
}

/* ---------------------------
   BadgeWidget (small utility)
   --------------------------- */
class BadgeWidget extends StatelessWidget {
  final String text;
  final bool filled;
  final Color? borderColor;
  final Color? gradientFrom;
  final Color? gradientTo;

  const BadgeWidget({
    super.key,
    required this.text,
    required this.filled,
    this.borderColor,
    this.gradientFrom,
    this.gradientTo,
  });

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              gradientFrom ?? const Color(0xFF7C3AED),
              gradientTo ?? const Color(0xFFDB2777),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor ?? const Color(0xFFE6E6F0)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
  }
}
