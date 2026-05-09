// lib/services/auth_service.dart
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
  Future<void> verifyEmail(String token) async {
    await _client.auth.verifyOTP(token: token, type: OtpType.email);
  }

  Future<void> resendVerificationEmail() async {
    final user = _client.auth.currentUser;
    if (user != null && user.email != null) {
      await _client.auth.resend(type: OtpType.email, email: user.email!);
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
