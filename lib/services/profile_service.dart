// lib/services/profile_service.dart
//
// ──────────────────────────────────────────────────────────────
//  SafeMap – ProfileService  (Production-Grade v3)
//
//  New in v3:
//  ✅ phone field added to UserProfile model + copyWith()
//  ✅ updateProfile() now saves phone number
//  ✅ searchProfileByPhone() — finds SafeMap user by phone
//  ✅ searchProfileByEmail() — fallback search by email
//  ✅ addContact() auto-links guardian_profile_id if found
//  ✅ updateContact() re-checks SafeMap status on edit
// ──────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Models/guardian_model.dart';

// ── Data models ──────────────────────────────────────────────

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final bool isVerified;
  final bool isGuardian;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    required this.isVerified,
    required this.isGuardian,
    required this.createdAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
    id:         m['id']         as String,
    name:       m['name']       as String? ?? '',
    email:      m['email']      as String? ?? '',
    phone:      m['phone']      as String?,  // ✅ NEW
    avatarUrl:  m['avatar_url'] as String?,
    isVerified: m['is_verified'] as bool? ?? false,
    isGuardian: m['is_guardian'] as bool? ?? false,
    createdAt:  DateTime.parse(m['created_at'] as String),
  );

  String get initials {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  String get memberSince {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return 'Member since ${months[createdAt.month - 1]} ${createdAt.year}';
  }

  // ✅ copyWith so we never have to repeat all fields on update
  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    bool?   isVerified,
    bool?   isGuardian,
  }) =>
      UserProfile(
        id:         id,
        name:       name       ?? this.name,
        email:      email      ?? this.email,
        phone:      phone      ?? this.phone,
        avatarUrl:  avatarUrl  ?? this.avatarUrl,
        isVerified: isVerified ?? this.isVerified,
        isGuardian: isGuardian ?? this.isGuardian,
        createdAt:  createdAt,
      );
}

class UserStats {
  final int safeWalks;
  final int reports;
  final int safetyPoints;

  const UserStats({
    required this.safeWalks,
    required this.reports,
    required this.safetyPoints,
  });

  factory UserStats.fromMap(Map<String, dynamic> m) => UserStats(
    safeWalks:    (m['safe_walks']    as num?)?.toInt() ?? 0,
    reports:      (m['reports']       as num?)?.toInt() ?? 0,
    safetyPoints: (m['safety_points'] as num?)?.toInt() ?? 0,
  );

  static const empty = UserStats(safeWalks: 0, reports: 0, safetyPoints: 0);
}

class UserSettings {
  final bool anonymousReporting;
  final bool locationServices;
  final bool voiceCommands;
  final bool safetyAlerts;
  final bool aiRecommendations;
  final bool communityUpdates;

  const UserSettings({
    this.anonymousReporting = true,
    this.locationServices   = true,
    this.voiceCommands      = true,
    this.safetyAlerts       = true,
    this.aiRecommendations  = true,
    this.communityUpdates   = false,
  });

  factory UserSettings.fromMap(Map<String, dynamic> m) => UserSettings(
    anonymousReporting: m['anonymous_reporting'] as bool? ?? true,
    locationServices:   m['location_services']   as bool? ?? true,
    voiceCommands:      m['voice_commands']       as bool? ?? true,
    safetyAlerts:       m['safety_alerts']        as bool? ?? true,
    aiRecommendations:  m['ai_recommendations']   as bool? ?? true,
    communityUpdates:   m['community_updates']    as bool? ?? false,
  );

  Map<String, dynamic> toMap() => {
    'anonymous_reporting': anonymousReporting,
    'location_services':   locationServices,
    'voice_commands':      voiceCommands,
    'safety_alerts':       safetyAlerts,
    'ai_recommendations':  aiRecommendations,
    'community_updates':   communityUpdates,
    'updated_at':          DateTime.now().toIso8601String(),
  };

  UserSettings copyWith({
    bool? anonymousReporting,
    bool? locationServices,
    bool? voiceCommands,
    bool? safetyAlerts,
    bool? aiRecommendations,
    bool? communityUpdates,
  }) =>
      UserSettings(
        anonymousReporting: anonymousReporting ?? this.anonymousReporting,
        locationServices:   locationServices   ?? this.locationServices,
        voiceCommands:      voiceCommands      ?? this.voiceCommands,
        safetyAlerts:       safetyAlerts       ?? this.safetyAlerts,
        aiRecommendations:  aiRecommendations  ?? this.aiRecommendations,
        communityUpdates:   communityUpdates   ?? this.communityUpdates,
      );
}

class UserAchievement {
  final String title;
  final String description;
  final String icon;
  final DateTime earnedAt;

  const UserAchievement({
    required this.title,
    required this.description,
    required this.icon,
    required this.earnedAt,
  });

  factory UserAchievement.fromMap(Map<String, dynamic> m) {
    final ach = m['achievements'] as Map<String, dynamic>? ?? {};
    return UserAchievement(
      title:       ach['title']       as String? ?? '',
      description: ach['description'] as String? ?? '',
      icon:        ach['icon']        as String? ?? 'award',
      earnedAt:    DateTime.parse(m['earned_at'] as String),
    );
  }
}

// ── Service ──────────────────────────────────────────────────

class ProfileService {
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  final _client = Supabase.instance.client;

  String get _uid {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('User not authenticated');
    return uid;
  }

  // ════════════════════════════════════════════════════════
  //  PROFILE
  // ════════════════════════════════════════════════════════

  Future<UserProfile> fetchProfile() async {
    debugPrint('[ProfileService] fetchProfile() called — uid: $_uid');

    // ✅ FIX 1: Use maybeSingle() — never throws on 0 rows
    var data = await _client
        .from('profiles')
        .select('*')
        .eq('id', _uid)
        .maybeSingle();

    if (data == null || 
        (data['name'] as String? ?? '').trim().isEmpty || 
        (data['phone'] as String? ?? '').trim().isEmpty) {
      // ✅ FIX 2: Profile missing/incomplete — restore/enrich from users/metadata
      debugPrint('[ProfileService] Profile missing/incomplete — restoring/enriching');

      // Try to get name/email/phone from public.users table (written at signup)
      Map<String, dynamic>? userData;
      try {
        userData = await _client
            .from('users')
            .select('full_name, email, phone')
            .eq('id', _uid)
            .maybeSingle();
        debugPrint('[ProfileService] public.users data: $userData');
      } catch (e) {
        debugPrint('[ProfileService] Could not read public.users: $e');
      }

      // Fall back to Supabase Auth metadata if users table also has no row
      final authUser = _client.auth.currentUser;
      final existingName = data?['name'] as String? ?? '';
      final existingEmail = data?['email'] as String? ?? '';
      final existingPhone = data?['phone'] as String? ?? '';

      final name  = existingName.isNotEmpty ? existingName : (userData?['full_name'] as String?
          ?? authUser?.userMetadata?['full_name'] as String?
          ?? authUser?.email?.split('@').first
          ?? 'User');
      final email = existingEmail.isNotEmpty ? existingEmail : (userData?['email'] as String?
          ?? authUser?.email
          ?? '');
      final phone = existingPhone.isNotEmpty ? existingPhone : (userData?['phone'] as String?
          ?? authUser?.userMetadata?['phone'] as String?);

      final cleanPhone = phone != null ? phone.replaceAll(RegExp(r'\D'), '') : null;

      // Upsert a new/updated row in profiles
      data = await _client.from('profiles').upsert({
        'id':          _uid,
        'name':        name,
        'email':       email,
        'phone':       cleanPhone,
        'is_verified': data?['is_verified'] ?? false,
        'is_guardian': data?['is_guardian'] ?? false,
        'created_at':  data?['created_at'] ?? DateTime.now().toIso8601String(),
        'updated_at':  DateTime.now().toIso8601String(),
      }).select().single();

      debugPrint('[ProfileService] profiles row created/updated — name: $name, phone: $cleanPhone');
    }

    debugPrint('[ProfileService] fetchProfile() success — name: ${data['name']}, phone: ${data['phone']}');
    return UserProfile.fromMap(data);
  }

  // ✅ UPDATED — now also saves phone number with sanitization
  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (name  != null && name.trim().isNotEmpty)  updates['name']  = name.trim();
    if (email != null && email.trim().isNotEmpty) updates['email'] = email.trim();
    if (phone != null) {
      final cleaned = phone.replaceAll(RegExp(r'\D'), '');
      updates['phone'] = cleaned.isEmpty ? null : cleaned;
    }

    await _client.from('profiles').update(updates).eq('id', _uid);
  }

  Stream<UserProfile> profileStream() {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', _uid)
        .map((rows) {
      if (rows.isEmpty) throw Exception('Profile not found');
      return UserProfile.fromMap(rows.first);
    });
  }

  // ── Avatar ────────────────────────────────────────────

  Future<String> uploadAvatar(File imageFile) async {
    final path  = '$_uid/avatar.jpg';
    final bytes = await imageFile.readAsBytes();

    await _client.storage.from('avatars').uploadBinary(
      path, bytes,
      fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
    );

    final publicUrl = _client.storage.from('avatars').getPublicUrl(path);

    await _client.from('profiles').update({
      'avatar_url': publicUrl,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', _uid);

    return publicUrl;
  }

  Future<void> removeAvatar() async {
    await _client.storage.from('avatars').remove(['$_uid/avatar.jpg']);
    await _client.from('profiles').update({
      'avatar_url': null,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', _uid);
  }

  // ════════════════════════════════════════════════════════
  //  GUARDIAN LOOKUP  ✅ NEW
  //
  //  Used when adding/editing emergency contacts.
  //  Searches the profiles table by phone or email to find
  //  the guardian's SafeMap profile ID for live tracking.
  // ════════════════════════════════════════════════════════

  /// Search for a SafeMap user by phone number.
  /// Returns null if nobody found or on error.
  Future<UserProfile?> searchProfileByPhone(String phone) async {
    try {
      final digits = phone.replaceAll(RegExp(r'\D'), '');
      if (digits.isEmpty) return null;

      if (digits.length < 10) {
        // Fallback for short numbers
        final rows = await _client
            .from('profiles')
            .select('id, name, email, phone, avatar_url, is_verified, is_guardian, created_at')
            .eq('phone', digits)
            .neq('id', _uid)        // exclude yourself
            .limit(1);

        if (rows.isEmpty) return null;
        return UserProfile.fromMap(rows.first);
      }

      // Match the last 10 digits to be immune to country-code prefixes (+92, 0300, etc.)
      final last10 = digits.substring(digits.length - 10);
      final rows = await _client
          .from('profiles')
          .select('id, name, email, phone, avatar_url, is_verified, is_guardian, created_at')
          .like('phone', '%$last10')
          .neq('id', _uid)        // exclude yourself
          .limit(1);

      if (rows.isEmpty) return null;
      return UserProfile.fromMap(rows.first);
    } catch (e) {
      debugPrint('[ProfileService] searchProfileByPhone error: $e');
      return null;
    }
  }

  /// Fallback search by email
  Future<UserProfile?> searchProfileByEmail(String email) async {
    try {
      final rows = await _client
          .from('profiles')
          .select('id, name, email, phone, avatar_url, is_verified, is_guardian, created_at')
          .eq('email', email.trim().toLowerCase())
          .neq('id', _uid)
          .limit(1);

      if (rows.isEmpty) return null;
      return UserProfile.fromMap(rows.first);
    } catch (e) {
      debugPrint('[ProfileService] searchProfileByEmail error: $e');
      return null;
    }
  }

  // ════════════════════════════════════════════════════════
  //  STATS
  // ════════════════════════════════════════════════════════

  Future<UserStats> fetchStats() async {
    try {
      // ✅ FIX 3: filter by user_id
      final data = await _client
          .from('user_stats')
          .select('*')
          .eq('user_id', _uid)
          .maybeSingle();
      debugPrint('[ProfileService] fetchStats — data: $data');
      return data == null ? UserStats.empty : UserStats.fromMap(data);
    } catch (e) {
      debugPrint('[ProfileService] fetchStats failed: $e');
      return UserStats.empty;
    }
  }

  // ════════════════════════════════════════════════════════
  //  EMERGENCY CONTACTS
  //  ✅ addContact + updateContact now auto-link guardian_profile_id
  // ════════════════════════════════════════════════════════

  Future<List<Guardian>> fetchContacts() async {
    try {
      // ✅ FIX 4: filter by user_id — was fetching all users' contacts
      final rows = await _client
          .from('emergency_contacts')
          .select('*')
          .eq('user_id', _uid)
          .order('created_at');
      debugPrint('[ProfileService] fetchContacts — ${rows.length} contacts');
      return rows.map((r) => Guardian.fromMap(r)).toList();
    } catch (e) {
      debugPrint('[ProfileService] fetchContacts failed: $e');
      return [];
    }
  }

  /// Add a contact.
  /// ✅ Automatically searches for guardian's SafeMap profile
  ///    by phone and links guardian_profile_id if found.
  /// Add a contact.
  /// ✅ Automatically searches for guardian's SafeMap profile
  ///    by phone and links guardian_profile_id if found.
  Future<Guardian> addContact(Guardian contact) async {
    try {
      final cleanPhone = contact.phone.replaceAll(RegExp(r'\D'), '');
      // Search for matching SafeMap profile by phone
      final guardianProfile = await searchProfileByPhone(cleanPhone);

      final row = await _client
          .from('emergency_contacts')
          .insert({
        'user_id':             _uid,
        'name':                contact.name.trim(),
        'phone':               cleanPhone,
        'relation':            contact.relation.trim(),
        // Link profile ID if found — null if not on SafeMap yet
        'guardian_profile_id': guardianProfile?.id,
      })
          .select()
          .single();

      return Guardian.fromMap(row);
    } on PostgrestException catch (e) {
      if (e.code == '23514') {
        throw Exception(
          'Invalid phone number. Please use format: +923001234567 or 03001234567',
        );
      }
      rethrow;
    }
  }

  Future<void> updateContact(Guardian contact) async {
    try {
      final cleanPhone = contact.phone.replaceAll(RegExp(r'\D'), '');
      // Re-check SafeMap status in case guardian joined since last save
      final guardianProfile = await searchProfileByPhone(cleanPhone);

      await _client
          .from('emergency_contacts')
          .update({
        'name':                contact.name.trim(),
        'phone':               cleanPhone,
        'relation':            contact.relation.trim(),
        'guardian_profile_id': guardianProfile?.id,
      })
          .eq('id', contact.id);
    } on PostgrestException catch (e) {
      if (e.code == '23514') {
        throw Exception(
          'Invalid phone number. Please use format: +923001234567 or 03001234567',
        );
      }
      rethrow;
    }
  }

  Future<void> deleteContact(String contactId) async {
    await _client
        .from('emergency_contacts')
        .delete()
        .eq('id', contactId);
  }

  // ════════════════════════════════════════════════════════
  //  SETTINGS
  // ════════════════════════════════════════════════════════

  Future<UserSettings> fetchSettings() async {
    try {
      // ✅ FIX 5: filter by user_id — was fetching all users' settings
      final data = await _client
          .from('user_settings')
          .select('*')
          .eq('user_id', _uid)
          .maybeSingle();
      debugPrint('[ProfileService] fetchSettings — data: $data');
      return data == null ? const UserSettings() : UserSettings.fromMap(data);
    } catch (e) {
      debugPrint('[ProfileService] fetchSettings failed: $e');
      return const UserSettings();
    }
  }

  Future<void> saveSettings(UserSettings settings) async {
    await _client.from('user_settings').upsert({
      'user_id': _uid,
      ...settings.toMap(),
    });
  }

  // ════════════════════════════════════════════════════════
  //  ACHIEVEMENTS
  // ════════════════════════════════════════════════════════

  Future<List<UserAchievement>> fetchAchievements() async {
    try {
      final rows = await _client
          .from('user_achievements')
          .select('earned_at, achievements(title, description, icon)')
          .order('earned_at', ascending: false);
      return rows.map((r) => UserAchievement.fromMap(r)).toList();
    } catch (e) {
      debugPrint('[ProfileService] fetchAchievements failed: $e');
      return [];
    }
  }

  // ════════════════════════════════════════════════════════
  //  AUTH
  // ════════════════════════════════════════════════════════

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ════════════════════════════════════════════════════════
  //  LOAD ALL
  // ════════════════════════════════════════════════════════

  Future<ProfileScreenData> loadAll() async {
    final results = await Future.wait([
      fetchProfile(),
      fetchStats(),
      fetchContacts(),
      fetchSettings(),
      fetchAchievements(),
    ]);

    return ProfileScreenData(
      profile:      results[0] as UserProfile,
      stats:        results[1] as UserStats,
      contacts:     results[2] as List<Guardian>,
      settings:     results[3] as UserSettings,
      achievements: results[4] as List<UserAchievement>,
    );
  }
}

class ProfileScreenData {
  final UserProfile           profile;
  final UserStats             stats;
  final List<Guardian>        contacts;
  final UserSettings          settings;
  final List<UserAchievement> achievements;

  const ProfileScreenData({
    required this.profile,
    required this.stats,
    required this.contacts,
    required this.settings,
    required this.achievements,
  });

  ProfileScreenData copyWith({UserProfile? profile}) => ProfileScreenData(
    profile:      profile      ?? this.profile,
    stats:        stats,
    contacts:     contacts,
    settings:     settings,
    achievements: achievements,
  );
}