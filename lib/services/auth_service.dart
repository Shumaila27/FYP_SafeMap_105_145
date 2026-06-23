// lib/services/auth_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Models/auth_model.dart';

class AuthService {
  final _client = Supabase.instance.client;

  // ── Login ─────────────────────────────────────────────
  Future<AuthResponse> login(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // ── Signup ────────────────────────────────────────────
  Future<AuthResponse> signup(SignupModel model) async {
    return await _client.auth.signUp(
      email: model.email,
      password: model.password,
      data: {
        'full_name': model.fullName, // stored in Supabase auth.users metadata
        'phone': model.phone,
      },
    );
  }

  // ── Email Verification ───────────────────────────────
  Future<void> verifyEmail(String email, String token) async {
    await _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
  }

  Future<void> resendVerificationEmail() async {
    final user = _client.auth.currentUser;
    if (user != null && user.email != null) {
      await _client.auth.resend(type: OtpType.email, email: user.email!);
    }
  }

  // ── Save User Data ───────────────────────────────
  Future<void> saveUserData(SignupModel model, String userId) async {
    final cleanPhone = model.phone.replaceAll(RegExp(r'\D'), '');

    try {
      // ✅ Use upsert to prevent duplicate key errors from triggers, and save cleaned phone
      await _client.from('users').upsert({
        'id': userId,
        'full_name': model.fullName,
        'email': model.email,
        'phone': cleanPhone,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[AuthService] public.users upsert failed: $e');
    }

    try {
      // ✅ Also write/upsert to public.profiles and save cleaned phone
      await _client.from('profiles').upsert({
        'id':          userId,
        'name':        model.fullName,
        'email':       model.email,
        'phone':       cleanPhone,
        'is_verified': false,
        'is_guardian': false,
        'created_at':  DateTime.now().toIso8601String(),
        'updated_at':  DateTime.now().toIso8601String(),
      });
      debugPrint('[AuthService] profiles row created/updated for uid: $userId');
    } catch (e) {
      throw Exception('Failed to create user profile: ${e.toString()}');
    }
  }

  // ── Password Reset ───────────────────────────────
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  // ── Logout ────────────────────────────────────────────
  Future<void> logout() async {
    await _client.auth.signOut();
  }

  // ── Getters ─────────────────────────────────────────
  User? get currentUser => _client.auth.currentUser;
  bool get isEmailVerified =>
      _client.auth.currentUser?.emailConfirmedAt != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
