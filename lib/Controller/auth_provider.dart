// lib/Controller/auth_provider.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../Models/auth_model.dart';

enum AuthStatus { idle, loading, success, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.idle;
  String? _errorMessage;

  // ── Getters ───────────────────────────────────────────
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.loading;

  // ── Login ─────────────────────────────────────────────
  Future<bool> login(AuthModel authModel) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.login(
        authModel.email,
        authModel.password,
      );

      if (response.user != null) {
        _status = AuthStatus.success;
        notifyListeners();
        return true;
      }

      _setError('Invalid email or password');
      return false;
    } catch (e) {
      _setError('Login failed: ${e.toString()}');
      return false;
    }
  }

  // ── Signup ────────────────────────────────────────────
  Future<bool> signup(SignupModel signupModel) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.signup(signupModel);

      if (response.user != null) {
        _status = AuthStatus.success;
        notifyListeners();
        return true;
      }

      _setError('Signup failed. Please try again.');
      return false;
    } catch (e) {
      _setError('Signup failed: ${e.toString()}');
      return false;
    }
  }

  // ── Email Verification ─────────────────────────────
  Future<bool> verifyEmail(String token) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.verifyEmail(token);
      _status = AuthStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Email verification failed: ${e.toString()}');
      return false;
    }
  }

  Future<bool> resendVerificationEmail() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.resendVerificationEmail();
      _status = AuthStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to resend verification email: ${e.toString()}');
      return false;
    }
  }

  // ── Forgot Password ───────────────────────────────
  Future<bool> forgotPassword(String email) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email);
      _status = AuthStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Password reset failed: ${e.toString()}');
      return false;
    }
  }

  // ── Logout ────────────────────────────────────────────
  Future<void> logout() async {
    await _authService.logout();
    _status = AuthStatus.idle;
    notifyListeners();
  }

  // ── Session Management ─────────────────────────────
  Future<void> checkAuthState() async {
    final user = _authService.currentUser;
    if (user != null) {
      _status = AuthStatus.success;
      notifyListeners();
    }
  }

  // ── Getters ───────────────────────────────────────────
  bool get isAuthenticated => _authService.currentUser != null;
  bool get isEmailVerified => _authService.isEmailVerified;

  // ── Helpers ───────────────────────────────────────────
  void _setError(String message) {
    _status = AuthStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  void reset() {
    _status = AuthStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }
}
