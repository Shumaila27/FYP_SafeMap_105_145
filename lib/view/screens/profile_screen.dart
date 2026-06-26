// lib/screens/profile/profile_screen.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../Models/guardian_model.dart';
import '../../services/guardian_service.dart';
import '../../services/profile_service.dart';
import '../../utils/app_colors.dart';
import '../widgets/app_bar.dart';
import 'help_support_new.dart';
import 'settings_screen.dart';
import 'about_screen.dart';
import 'registration_screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _svc = ProfileService.instance;

  bool _loading = true;
  String? _error;

  late UserProfile _profile;
  late UserStats _stats;
  late List<Guardian> _contacts;
  late UserSettings _settings;
  late List<UserAchievement> _achievements;

  File? _localAvatarFile;
  StreamSubscription<UserProfile>? _profileSub;

  final TextEditingController _nameCtrl  = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController(); // ✅ Added
  final TextEditingController _cNameCtrl  = TextEditingController();
  final TextEditingController _cPhoneCtrl = TextEditingController();
  final TextEditingController _cRelCtrl   = TextEditingController();

  String? _nameError;
  String? _emailError;
  String? _phoneError; // ✅ Added
  String? _cNameError;
  String? _cPhoneError;
  String? _cRelError;

  bool _savingProfile   = false;
  bool _savingContact   = false;
  bool _updatingContact = false;

  @override
  void initState() {
    super.initState();
    debugPrint('Profile Screen initialized');
    debugPrint('Current user: ${Supabase.instance.client.auth.currentUser?.id}');
    _loadAll();
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose(); // ✅ Added
    _cNameCtrl.dispose();
    _cPhoneCtrl.dispose();
    _cRelCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    debugPrint('[ProfileScreen] _loadAll() started');
    setState(() { _loading = true; _error = null; });
    try {
      debugPrint('[ProfileScreen] Calling ProfileService.loadAll()');
      // Add a 15-second timeout so we never spin forever if Supabase is slow
      final data = await _svc.loadAll().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception(
          'Profile load timed out. Please check your internet connection and try again.',
        ),
      );
      if (!mounted) return;
      debugPrint('[ProfileScreen] loadAll() succeeded — profile: ${data.profile.name}');
      setState(() {
        _profile      = data.profile;
        _stats        = data.stats;
        _contacts     = data.contacts;
        _settings     = data.settings;
        _achievements = data.achievements;
        _nameCtrl.text  = _profile.name;
        _emailCtrl.text = _profile.email;
        _phoneCtrl.text = _profile.phone ?? '';
        _loading        = false;
      });

      _profileSub?.cancel();
      _profileSub = _svc.profileStream().listen(
            (updatedProfile) {
          if (!mounted) return;
          debugPrint('[ProfileScreen] profileStream update — name: ${updatedProfile.name}');
          setState(() => _profile = updatedProfile);
        },
        onError: (e) => debugPrint('[ProfileScreen] profileStream error: $e'),
      );
    } catch (e, stack) {
      debugPrint('[ProfileScreen] _loadAll() FAILED: $e');
      debugPrint('[ProfileScreen] Stack trace: $stack');
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ── Avatar ─────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    try {
      final xFile = await ImagePicker().pickImage(
        source: source, maxWidth: 512, maxHeight: 512, imageQuality: 80,
      );
      if (xFile == null) return;
      final file = File(xFile.path);

      setState(() => _localAvatarFile = file);

      final url = await _svc.uploadAvatar(file);
      setState(() => _profile = _profile.copyWith(avatarUrl: url));
      _snack('Profile picture updated!', Colors.green);
    } catch (e) {
      _snack('Upload failed: $e', Colors.red);
    }
  }

  Future<void> _removeAvatar() async {
    await _svc.removeAvatar();
    setState(() {
      _localAvatarFile = null;
      _profile = _profile.copyWith(avatarUrl: null);
    });
    _snack('Photo removed', Colors.orange);
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const Text('Update Profile Picture',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppColor.appSecondary),
              title: const Text('Take Photo'),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppColor.appSecondary),
              title: const Text('Choose from Gallery'),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
            ),
            if (_localAvatarFile != null || _profile.avatarUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Photo'),
                onTap: () { Navigator.pop(context); _removeAvatar(); },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Edit profile ───────────────────────────────────────────

  void _showEditProfileDialog() {
    _nameCtrl.text  = _profile.name;
    _emailCtrl.text = _profile.email;
    _phoneCtrl.text = _profile.phone ?? '';
    _nameError = _emailError = _phoneError = null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _textField(
                ctrl:      _nameCtrl,
                label:     'Name',
                hint:      'Enter your name',
                errorText: _nameError,
                onChanged: (_) => setD(() => _nameError = null),
              ),
              const SizedBox(height: 16),
              _textField(
                ctrl:         _emailCtrl,
                label:        'Email',
                hint:         'Enter your email',
                errorText:    _emailError,
                keyboardType: TextInputType.emailAddress,
                onChanged:    (_) => setD(() => _emailError = null),
              ),
              const SizedBox(height: 16),
              _textField(
                ctrl:         _phoneCtrl,
                label:        'Phone',
                hint:         'Enter your phone number',
                errorText:    _phoneError,
                keyboardType: TextInputType.phone,
                onChanged:    (_) => setD(() => _phoneError = null),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _savingProfile ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.appSecondary),
              onPressed: _savingProfile ? null : () async {
                String? nameErr, emailErr, phoneErr;
                if (_nameCtrl.text.trim().isEmpty) {
                  nameErr = 'Name cannot be empty';
                }
                if (_emailCtrl.text.trim().isEmpty) {
                  emailErr = 'Email cannot be empty';
                } else if (!_emailCtrl.text.contains('@')) {
                  emailErr = 'Enter a valid email address';
                }
                phoneErr = _validatePhone(_phoneCtrl.text);

                if (nameErr != null || emailErr != null || phoneErr != null) {
                  setD(() {
                    _nameError = nameErr;
                    _emailError = emailErr;
                    _phoneError = phoneErr;
                  });
                  return;
                }

                setD(() => _savingProfile = true);
                try {
                  await _svc.updateProfile(
                    name:  _nameCtrl.text.trim(),
                    email: _emailCtrl.text.trim(),
                    phone: _phoneCtrl.text.trim(),
                  );
                  setState(() {
                    _profile = _profile.copyWith(
                      name:  _nameCtrl.text.trim(),
                      email: _emailCtrl.text.trim(),
                      phone: _phoneCtrl.text.trim().replaceAll(RegExp(r'\D'), ''),
                    );
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  _snack('Profile updated successfully!', Colors.green);
                } catch (e) {
                  _snack(e.toString().replaceAll('Exception: ', ''), Colors.red,
                      duration: const Duration(seconds: 5));
                } finally {
                  if (ctx.mounted) setD(() => _savingProfile = false);
                }
              },
              child: _savingProfile
                  ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Emergency contacts ─────────────────────────────────────

  void _showContactsDialog() {
    _cNameError = _cPhoneError = _cRelError = null;
    _cNameCtrl.clear(); _cPhoneCtrl.clear(); _cRelCtrl.clear();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Emergency Contacts'),
          content: SizedBox(
            width: double.maxFinite,
            height: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _contactForm(
                    onAdd: () async {
                      final g = await _svc.addContact(Guardian(
                        id:       '',
                        name:     _cNameCtrl.text.trim(),
                        phone:    _cPhoneCtrl.text.trim(),
                        relation: _cRelCtrl.text.trim(),
                      ));
                      setState(() => _contacts.add(g));

                      GuardianService().addToCache(g); // ✅ ADDED — instant sync to SafeWalkScreen

                      setD(() {});
                      _cNameCtrl.clear();
                      _cPhoneCtrl.clear();
                      _cRelCtrl.clear();
                      _snack('Contact added successfully', Colors.green);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Existing Contacts',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._contacts.asMap().entries.map((entry) {
                    final i = entry.key;
                    final g = entry.value;
                    return _existingContactTile(
                      index:     i,
                      guardian:  g,
                      setD:      setD,
                      parentCtx: context,
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _existingContactTile({
    required int index,
    required Guardian guardian,
    required StateSetter setD,
    required BuildContext parentCtx,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _avatarTile(index, guardian.initials),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(guardian.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(guardian.phone,
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 12)),
                Text(guardian.relation,
                    style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                        fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
            onPressed: () {
              _cNameCtrl.text  = guardian.name;
              _cPhoneCtrl.text = guardian.phone;
              _cRelCtrl.text   = guardian.relation;
              _showEditContactDialog(guardian, setD);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            onPressed: () async {
              try {
                await _svc.deleteContact(guardian.id);
                setState(() =>
                    _contacts.removeWhere((c) => c.id == guardian.id));

                GuardianService().removeFromCache(guardian.id); // ✅ ADDED — instant sync to SafeWalkScreen

                setD(() {});
                _snack('Contact removed', Colors.orange);
              } catch (e) {
                _snack('Failed: $e', Colors.red);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showEditContactDialog(Guardian guardian, StateSetter setD) {
    _cNameCtrl.text  = guardian.name;
    _cPhoneCtrl.text = guardian.phone;
    _cRelCtrl.text   = guardian.relation;
    _cNameError = _cPhoneError = _cRelError = null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setE) => AlertDialog(
          title: const Text('Edit Contact'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _textField(
                ctrl:      _cNameCtrl,
                label:     'Name',
                hint:      'Contact name',
                errorText: _cNameError,
                onChanged: (_) => setE(() => _cNameError = null),
              ),
              const SizedBox(height: 12),
              _textField(
                ctrl:         _cPhoneCtrl,
                label:        'Phone',
                hint:         '+923001234567 or 03001234567',
                errorText:    _cPhoneError,
                keyboardType: TextInputType.phone,
                onChanged:    (_) => setE(() => _cPhoneError = null),
              ),
              const SizedBox(height: 12),
              _textField(
                ctrl:      _cRelCtrl,
                label:     'Relation',
                hint:      'e.g. Sister, Friend',
                errorText: _cRelError,
                onChanged: (_) => setE(() => _cRelError = null),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _updatingContact ? null : () {
                _cNameCtrl.clear();
                _cPhoneCtrl.clear();
                _cRelCtrl.clear();
                Navigator.pop(ctx);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.appSecondary),
              onPressed: _updatingContact ? null : () async {
                String? nameErr, phoneErr, relErr;
                if (_cNameCtrl.text.trim().isEmpty) nameErr = 'Name is required';
                if (_cRelCtrl.text.trim().isEmpty)  relErr  = 'Relation is required';
                phoneErr = _validatePhone(_cPhoneCtrl.text);

                if (nameErr != null || phoneErr != null || relErr != null) {
                  setE(() {
                    _cNameError  = nameErr;
                    _cPhoneError = phoneErr;
                    _cRelError   = relErr;
                  });
                  return;
                }

                setE(() => _updatingContact = true);
                final updated = guardian.copyWith(
                  name:     _cNameCtrl.text.trim(),
                  phone:    _cPhoneCtrl.text.trim(),
                  relation: _cRelCtrl.text.trim(),
                );
                try {
                  await _svc.updateContact(updated);
                  setState(() {
                    final idx =
                    _contacts.indexWhere((c) => c.id == guardian.id);
                    if (idx != -1) _contacts[idx] = updated;
                  });

                  GuardianService().updateInCache(updated); // ✅ ADDED — instant sync to SafeWalkScreen

                  setD(() {});
                  _cNameCtrl.clear();
                  _cPhoneCtrl.clear();
                  _cRelCtrl.clear();
                  if (ctx.mounted) Navigator.pop(ctx);
                  _snack('Contact updated successfully!', Colors.green);
                } catch (e) {
                  final msg = e.toString().replaceAll('Exception: ', '');
                  if (msg.toLowerCase().contains('phone')) {
                    setE(() => _cPhoneError = msg);
                  } else {
                    _snack(msg, Colors.red,
                        duration: const Duration(seconds: 5));
                  }
                } finally {
                  if (ctx.mounted) setE(() => _updatingContact = false);
                }
              },
              child: _updatingContact
                  ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
                  : const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Settings toggles ───────────────────────────────────────

  Future<void> _saveSetting(UserSettings updated) async {
    setState(() => _settings = updated);
    try {
      await _svc.saveSettings(updated);
    } catch (e) {
      _snack('Settings save failed: $e', Colors.red);
    }
  }

  // ── Logout ─────────────────────────────────────────────────

  Future<void> _handleLogout() async {
    try {
      GuardianService().reset();
      await _svc.signOut();
      if (!mounted) return;
      _snack('Logged out successfully', Colors.green);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
      );
    } catch (e) {
      _snack('Logout failed: $e', Colors.red);
    }
  }

  // ── Helpers ────────────────────────────────────────────────

  void _snack(String msg, Color bg,
      {Duration duration = const Duration(seconds: 3)}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          Icon(
            bg == Colors.red
                ? Icons.error_outline
                : bg == Colors.green
                ? Icons.check_circle_outline
                : Icons.info_outline,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Text(msg,
                  style: const TextStyle(color: Colors.white))),
        ]),
        backgroundColor: bg,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ));
  }

  static final _phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');

  String? _validatePhone(String value) {
    final cleaned =
    value.trim().replaceAll(' ', '').replaceAll('-', '');
    if (cleaned.isEmpty) return 'Phone number is required';
    if (!_phoneRegex.hasMatch(cleaned)) {
      return 'Use format: +923001234567 or 03001234567 (10–15 digits)';
    }
    return null;
  }

  Widget _textField({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    String? errorText,
    TextInputType keyboardType = TextInputType.text,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller:   ctrl,
      keyboardType: keyboardType,
      onChanged:    onChanged,
      decoration: InputDecoration(
        labelText:     label,
        hintText:      hint,
        errorText:     errorText,
        errorMaxLines: 2,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColor.appSecondary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _avatarTile(int index, String initials) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: index == 0
              ? [const Color(0xFF3B82F6), const Color(0xFF06B6D4)]
              : [const Color(0xFFF472B6), const Color(0xFFFB7185)],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(initials,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
      ),
    );
  }

  Widget _contactForm({required Future<void> Function() onAdd}) {
    return StatefulBuilder(
      builder: (ctx, setF) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Add New Contact',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center),
            const SizedBox(height: 10),
            _textField(
              ctrl:      _cNameCtrl,
              label:     'Name',
              hint:      'Enter contact name',
              errorText: _cNameError,
              onChanged: (_) => setF(() => _cNameError = null),
            ),
            const SizedBox(height: 10),
            _textField(
              ctrl:         _cPhoneCtrl,
              label:        'Phone',
              hint:         '+923001234567 or 03001234567',
              errorText:    _cPhoneError,
              keyboardType: TextInputType.phone,
              onChanged:    (_) => setF(() => _cPhoneError = null),
            ),
            const SizedBox(height: 10),
            _textField(
              ctrl:      _cRelCtrl,
              label:     'Relation',
              hint:      'e.g. Sister, Friend, Mother',
              errorText: _cRelError,
              onChanged: (_) => setF(() => _cRelError = null),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _savingContact ? null : () async {
                String? nameErr, phoneErr, relErr;
                if (_cNameCtrl.text.trim().isEmpty) {
                  nameErr = 'Name is required';
                }
                if (_cRelCtrl.text.trim().isEmpty) {
                  relErr = 'Relation is required';
                }
                phoneErr = _validatePhone(_cPhoneCtrl.text);

                if (nameErr != null ||
                    phoneErr != null ||
                    relErr != null) {
                  setF(() {
                    _cNameError  = nameErr;
                    _cPhoneError = phoneErr;
                    _cRelError   = relErr;
                  });
                  return;
                }

                setF(() => _savingContact = true);
                try {
                  await onAdd();
                  setF(() {
                    _cNameError  = null;
                    _cPhoneError = null;
                    _cRelError   = null;
                  });
                } catch (e) {
                  final msg =
                  e.toString().replaceAll('Exception: ', '');
                  if (msg.toLowerCase().contains('phone')) {
                    setF(() => _cPhoneError = msg);
                  } else {
                    _snack(msg, Colors.red,
                        duration: const Duration(seconds: 5));
                  }
                } finally {
                  setF(() => _savingContact = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                AppColor.getInteractivePrimary(context),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _savingContact
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
                  : const Text('Add Contact',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppMainBar(showBack: false),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Failed to load profile',
                style: TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(
                onPressed: _loadAll,
                child: const Text('Retry')),
          ],
        ),
      )
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProfileHeader(
                    profile:    _profile,
                    localImage: _localAvatarFile,
                    onImageTap: _showImagePickerSheet,
                    onEditTap:  _showEditProfileDialog,
                  ),
                  const SizedBox(height: 15),

                  StatsCards(stats: _stats),
                  const SizedBox(height: 15),

                  if (_achievements.isNotEmpty)
                    ContributionBadgeSection(
                        achievement: _achievements.first),
                  if (_achievements.isEmpty)
                    ContributionBadgeSection(achievement: null),
                  const SizedBox(height: 15),

                  EmergencyContactsSection(
                    contacts:       _contacts,
                    onEditContacts: _showContactsDialog,
                  ),
                  const SizedBox(height: 15),

                  PrivacySettingsSection(
                    settings: _settings,
                    onAnonymousChanged: (v) => _saveSetting(
                        _settings.copyWith(anonymousReporting: v)),
                    onLocationChanged: (v) => _saveSetting(
                        _settings.copyWith(locationServices: v)),
                    onVoiceChanged: (v) => _saveSetting(
                        _settings.copyWith(voiceCommands: v)),
                  ),
                  const SizedBox(height: 18),

                  NotificationsSettingsSection(
                    settings: _settings,
                    onSafetyAlertsChanged: (v) => _saveSetting(
                        _settings.copyWith(safetyAlerts: v)),
                    onAiRecommendationsChanged: (v) => _saveSetting(
                        _settings.copyWith(aiRecommendations: v)),
                    onCommunityUpdatesChanged: (v) => _saveSetting(
                        _settings.copyWith(communityUpdates: v)),
                  ),
                  const SizedBox(height: 18),

                  MenuOptionsSection(),
                  const SizedBox(height: 18),

                  LogoutButtonSection(onLogout: _handleLogout),
                  const SizedBox(height: 12),

                  Column(children: [
                    Text('SafeMap v1.0.0',
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Making Pakistan safer for everyone',
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            fontWeight: FontWeight.w500)),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SUB-WIDGETS  — all unchanged from your original
// ─────────────────────────────────────────────────────────────

class ProfileHeader extends StatelessWidget {
  final UserProfile  profile;
  final File?        localImage;
  final VoidCallback onImageTap;
  final VoidCallback onEditTap;

  const ProfileHeader({
    super.key,
    required this.profile,
    this.localImage,
    required this.onImageTap,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget avatarChild;
    if (localImage != null) {
      avatarChild =
          Image.file(localImage!, fit: BoxFit.cover, width: 70, height: 70);
    } else if (profile.avatarUrl != null) {
      avatarChild = Image.network(
        profile.avatarUrl!,
        fit: BoxFit.cover,
        width: 70,
        height: 70,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : const Center(child: CircularProgressIndicator()),
        errorBuilder: (_, __, ___) => _initialsWidget(),
      );
    } else {
      avatarChild = _initialsWidget();
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
            const Color(0xFF1E293B),
            const Color(0xFF334155),
            const Color(0xFF475569)
          ]
              : [
            const Color(0xFFF3E8FF),
            const Color(0xFFFCE8F8),
            const Color(0xFFFFE6F0)
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDark
                ? const Color(0xFF475569)
                : const Color(0xFFE9D8FF),
            width: 1.6),
        boxShadow: const [
          BoxShadow(
              color: Color.fromRGBO(0, 0, 0, .06),
              blurRadius: 10,
              offset: Offset(0, 6))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: onImageTap,
            child: Stack(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: isDark
                            ? const Color(0xFF475569)
                            : Colors.white,
                        width: 4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: avatarChild,
                  ),
                ),
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
                          color: AppColor.appSecondary, width: 2),
                    ),
                    child: Icon(Icons.camera_alt,
                        color: AppColor.appSecondary, size: 14),
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
                Row(children: [
                  Expanded(
                    child: Text(profile.name,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColor.getTextPrimary(context))),
                  ),
                  GestureDetector(
                    onTap: onEditTap,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColor.getInteractivePrimary(context)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.edit,
                          color: AppColor.getIconPrimary(context),
                          size: 16),
                    ),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(profile.email,
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColor.getTextSecondary(context),
                        fontWeight: FontWeight.w500)),
                if (profile.phone != null && profile.phone!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(profile.phone!,
                      style: TextStyle(
                          fontSize: 13,
                          color: AppColor.getTextSecondary(context),
                          fontWeight: FontWeight.w500)),
                ],
                const SizedBox(height: 4),
                Text(profile.memberSince,
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColor.getTextSecondary(context),
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 10),
                Row(children: [
                  if (profile.isVerified)
                    const BadgeWidget(
                        text: 'Verified',
                        filled: true,
                        gradientFrom: Color(0xFF6D28D9),
                        gradientTo: Color(0xFFDB2777)),
                  if (profile.isVerified) const SizedBox(width: 8),
                  if (profile.isGuardian)
                    BadgeWidget(
                      text: 'Active Guardian',
                      filled: false,
                      borderColor: isDark
                          ? const Color(0xFF4B5563)
                          : const Color(0xFFE9D8FF),
                    ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _initialsWidget() => Container(
    width: 70,
    height: 70,
    decoration: BoxDecoration(
      gradient: LinearGradient(
          colors: [AppColor.appSecondary, AppColor.appPrimary]),
    ),
    child: Center(
      child: Text(profile.initials,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold)),
    ),
  );
}

// ── Stats ─────────────────────────────────────────────────────

class StatsCards extends StatelessWidget {
  final UserStats stats;
  const StatsCards({super.key, required this.stats});

  Widget _stat({
    required BuildContext context,
    required Widget icon,
    required String value,
    required String label,
    required Gradient gradient,
    required Color valueColor,
  }) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding:
      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDark
                ? const Color(0xFF334155)
                : const Color(0xFFE6E6F0),
            width: 1.4),
      ),
      child: Column(children: [
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12)),
          child: Center(child: icon),
        ),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: valueColor)),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
          child: _stat(
            context: context,
            icon: const Icon(LucideIcons.shield,
                size: 22, color: Colors.white),
            value: '${stats.safeWalks}',
            label: 'Safe Walks',
            gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFFDB2777)]),
            valueColor: const Color(0xFF6D28D9),
          )),
      const SizedBox(width: 12),
      Expanded(
          child: _stat(
            context: context,
            icon: const Icon(LucideIcons.mapPin,
                size: 22, color: Colors.white),
            value: '${stats.reports}',
            label: 'Reports',
            gradient: const LinearGradient(
                colors: [Color(0xFFF97316), Color(0xFFF43F5E)]),
            valueColor: const Color(0xFFFB923C),
          )),
      const SizedBox(width: 12),
      Expanded(
          child: _stat(
            context: context,
            icon: const Icon(LucideIcons.award,
                size: 22, color: Colors.white),
            value: '${stats.safetyPoints}',
            label: 'Safety Points',
            gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)]),
            valueColor: const Color(0xFF10B981),
          )),
    ]);
  }
}

// ── Achievement badge ─────────────────────────────────────────

class ContributionBadgeSection extends StatelessWidget {
  final UserAchievement? achievement;
  const ContributionBadgeSection({super.key, this.achievement});

  @override
  Widget build(BuildContext context) {
    final title = achievement?.title       ?? 'Keep Going!';
    final desc  = achievement?.description ??
        'Complete more walks to earn badges.';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFFFF7ED), Color(0xFFFFF1CC)]),
        borderRadius: BorderRadius.circular(20),
        border:
        Border.all(color: const Color(0xFFFDE68A), width: 1.6),
      ),
      child: Row(children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFFCD34D)]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(
              child: Icon(LucideIcons.award,
                  color: Colors.white, size: 28)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF92400E))),
              const SizedBox(height: 4),
              Text(desc,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF92400E))),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Emergency contacts ────────────────────────────────────────

class EmergencyContactsSection extends StatelessWidget {
  final List<Guardian> contacts;
  final VoidCallback   onEditContacts;
  const EmergencyContactsSection({
    super.key,
    required this.contacts,
    required this.onEditContacts,
  });

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDark
                ? const Color(0xFF334155)
                : const Color(0xFFE6E6F0),
            width: 1.4),
      ),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(children: [
                const Icon(LucideIcons.users,
                    color: Color(0xFF6D28D9), size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Emergency Contacts',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            ),
            TextButton(
              onPressed: onEditContacts,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.edit,
                      color: Color(0xFF6D28D9), size: 16),
                  SizedBox(width: 4),
                  Text('Edit',
                      style: TextStyle(
                          color: Color(0xFF6D28D9),
                          fontWeight: FontWeight.w700)),
                  SizedBox(width: 4),
                  Icon(LucideIcons.chevronRight,
                      color: Color(0xFF6D28D9), size: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (contacts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('No emergency contacts yet.',
                style: TextStyle(color: cs.onSurfaceVariant)),
          ),
        ...contacts.asMap().entries.map((e) {
          final i = e.key;
          final g = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest
                    .withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE9E9F0)),
              ),
              child: Row(children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: i == 0
                          ? [
                        const Color(0xFF3B82F6),
                        const Color(0xFF06B6D4)
                      ]
                          : [
                        const Color(0xFFF472B6),
                        const Color(0xFFFB7185)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(g.initials,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(g.name,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface)),
                      const SizedBox(height: 4),
                      Text(g.phone,
                          style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ]),
            ),
          );
        }),
      ]),
    );
  }
}

// ── Privacy settings ──────────────────────────────────────────

class PrivacySettingsSection extends StatelessWidget {
  final UserSettings       settings;
  final ValueChanged<bool> onAnonymousChanged;
  final ValueChanged<bool> onLocationChanged;
  final ValueChanged<bool> onVoiceChanged;

  const PrivacySettingsSection({
    super.key,
    required this.settings,
    required this.onAnonymousChanged,
    required this.onLocationChanged,
    required this.onVoiceChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDark
                ? const Color(0xFF334155)
                : const Color(0xFFE6E6F0),
            width: 1.4),
      ),
      child: Column(children: [
        Row(children: [
          const Icon(LucideIcons.shield, color: Color(0xFF6D28D9)),
          const SizedBox(width: 8),
          Text('Privacy & Safety',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface)),
        ]),
        const SizedBox(height: 12),
        _tile(context, 'Anonymous Reporting',
            'Keep your identity private',
            settings.anonymousReporting, onAnonymousChanged),
        const SizedBox(height: 8),
        _tile(context, 'Location Services',
            'For accurate safety scores',
            settings.locationServices, onLocationChanged),
        const SizedBox(height: 8),
        _tile(context, 'Voice Commands', 'Hands-free panic button',
            settings.voiceCommands, onVoiceChanged),
      ]),
    );
  }

  Widget _tile(BuildContext ctx, String title, String sub, bool val,
      ValueChanged<bool> cb) {
    final cs = Theme.of(ctx).colorScheme;
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface)),
                const SizedBox(height: 4),
                Text(sub,
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600)),
              ]),
        ),
        Transform.scale(
          scale: 0.7,
          child: Switch(
              value: val,
              onChanged: cb,
              activeColor: AppColor.appSecondary),
        ),
      ]),
    );
  }
}

// ── Notification settings ─────────────────────────────────────

class NotificationsSettingsSection extends StatelessWidget {
  final UserSettings       settings;
  final ValueChanged<bool> onSafetyAlertsChanged;
  final ValueChanged<bool> onAiRecommendationsChanged;
  final ValueChanged<bool> onCommunityUpdatesChanged;

  const NotificationsSettingsSection({
    super.key,
    required this.settings,
    required this.onSafetyAlertsChanged,
    required this.onAiRecommendationsChanged,
    required this.onCommunityUpdatesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDark
                ? const Color(0xFF334155)
                : const Color(0xFFE6E6F0),
            width: 1.4),
      ),
      child: Column(children: [
        Row(children: [
          const Icon(LucideIcons.bell, color: Color(0xFF6D28D9)),
          const SizedBox(width: 8),
          Text('Notifications',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface)),
        ]),
        const SizedBox(height: 12),
        _tile(
            ctx: context,
            title: 'Safety Alerts',
            sub: 'High-risk area warnings',
            val: settings.safetyAlerts,
            cb: onSafetyAlertsChanged),
        const SizedBox(height: 8),
        _tile(
            ctx: context,
            title: 'AI Recommendations',
            sub: 'Route suggestions',
            val: settings.aiRecommendations,
            cb: onAiRecommendationsChanged),
        const SizedBox(height: 8),
        _tile(
            ctx: context,
            title: 'Community Updates',
            sub: 'New reports nearby',
            val: settings.communityUpdates,
            cb: onCommunityUpdatesChanged),
      ]),
    );
  }

  Widget _tile({
    required BuildContext ctx,
    required String title,
    required String sub,
    required bool val,
    required ValueChanged<bool> cb,
  }) {
    final cs = Theme.of(ctx).colorScheme;
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface)),
                const SizedBox(height: 4),
                Text(sub,
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600)),
              ]),
        ),
        Transform.scale(
          scale: 0.8,
          child: Switch(
              value: val,
              onChanged: cb,
              activeColor: AppColor.appSecondary),
        ),
      ]),
    );
  }
}

// ── Menu options & logout ─────────────────────────────────────

class MenuOptionsSection extends StatelessWidget {
  const MenuOptionsSection({super.key});

  Widget _btn(BuildContext ctx, Widget icon, String title,
      VoidCallback? onTap) {
    final cs     = Theme.of(ctx).colorScheme;
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return SizedBox(
      height: 50,
      child: TextButton(
        onPressed: onTap ?? () {},
        style: TextButton.styleFrom(
          backgroundColor: cs.surfaceContainerLowest,
          foregroundColor: cs.onSurface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          side: BorderSide(
              color: isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFE5E7EB)),
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8)),
            child: Center(child: icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface)),
          ),
          Icon(LucideIcons.chevronRight,
              color: cs.onSurfaceVariant),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(children: [
      _btn(
          context,
          Icon(LucideIcons.settings, color: cs.onSurfaceVariant),
          'Settings',
              () => Navigator.push(context,
              MaterialPageRoute(
                  builder: (_) => const SettingsScreen()))),
      const SizedBox(height: 8),
      _btn(
          context,
          Icon(LucideIcons.info, color: cs.onSurfaceVariant),
          'About',
              () => Navigator.push(context,
              MaterialPageRoute(
                  builder: (_) => const AboutScreen()))),
      const SizedBox(height: 8),
      _btn(
          context,
          Icon(Icons.help, color: cs.onSurfaceVariant),
          'Help & Support',
              () => Navigator.push(context,
              MaterialPageRoute(
                  builder: (_) => const HelpSupportScreen()))),
    ]);
  }
}

class LogoutButtonSection extends StatelessWidget {
  final VoidCallback onLogout;
  const LogoutButtonSection({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 56,
      child: OutlinedButton.icon(
        onPressed: onLogout,
        icon: const Icon(LucideIcons.logOut,
            color: Color(0xFFDC2626)),
        label: const Text('Logout',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFDC2626))),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
              color: isDark
                  ? const Color(0xFF7F1D1D)
                  : const Color(0xFFFCA5A5),
              width: 1.6),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          backgroundColor: cs.surfaceContainerLowest,
        ),
      ),
    );
  }
}

class BadgeWidget extends StatelessWidget {
  final String text;
  final bool   filled;
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
        padding:
        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            gradientFrom ?? const Color(0xFF7C3AED),
            gradientTo   ?? const Color(0xFFDB2777),
          ]),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      );
    }
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: borderColor ?? const Color(0xFFE6E6F0)),
      ),
      child: Text(text,
          style: TextStyle(
              color: cs.onSurface, fontWeight: FontWeight.w700)),
    );
  }
}