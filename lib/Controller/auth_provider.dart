// lib/Controller/auth_provider.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../Models/auth_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthStatus { idle, loading, success, error }

class AuthProvider extends ChangeNotifier {
  static const String emailVerificationRequired = 'EMAIL_VERIFICATION_REQUIRED';

  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.idle;
  String? _errorMessage;

  // ── Getters ───────────────────────────────────────────
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _authService.currentUser != null;

  // ── Login ─────────────────────────────────────────────
  Future<bool> login(AuthModel authModel) async {
    // Input validation
    if (authModel.email.isEmpty) {
      _setError('Email is required');
      return false;
    }
    if (authModel.password.isEmpty) {
      _setError('Password is required');
      return false;
    }

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
      if (e is AuthException) {
        _setError(_mapAuthError(e));
      } else {
        _setError(
          'Login failed. Please check your internet connection and try again.',
        );
      }
      return false;
    }
  }

  // ── Signup ────────────────────────────────────────────
  Future<bool> signup(SignupModel signupModel) async {
    // Input validation
    if (signupModel.fullName.isEmpty) {
      _setError('Full name is required');
      return false;
    }
    if (signupModel.email.isEmpty) {
      _setError('Email is required');
      return false;
    }
    if (signupModel.password.isEmpty) {
      _setError('Password is required');
      return false;
    }
    if (signupModel.phone.isEmpty) {
      _setError('Phone number is required');
      return false;
    }

    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.signup(signupModel);

      if (response.user != null) {
        // Save user data to Supabase table
        await _authService.saveUserData(signupModel, response.user!.id);

        // Since email confirmation is disabled, user is automatically signed up and logged in
        _status = AuthStatus.success;
        notifyListeners();
        return true;
      }

      _setError('Signup failed. Please try again.');
      return false;
    } catch (e) {
      if (e is AuthException) {
        _setError(_mapAuthError(e));
      } else if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        _setError('No internet connection. Please check your network.');
      } else {
        _setError('Something went wrong. Please try again.');
      }
      return false;
    }
  }

  // ── Supabase Error Mapper ─────────────────────────────
  String _mapAuthError(AuthException e) {
    final msg = e.message.toLowerCase();
    final code = e.statusCode;

    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid email or password')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Please verify your email before logging in. Check your inbox.';
    }
    if (msg.contains('user not found')) {
      return 'No account found with this email. Please sign up first.';
    }
    if (msg.contains('user already registered') ||
        msg.contains('already been registered')) {
      return 'An account with this email already exists. Please login.';
    }
    if (msg.contains('password should be at least') ||
        msg.contains('weak_password') ||
        msg.contains('password is too weak')) {
      return 'Password must be at least 8 characters with mixed characters.';
    }
    if (msg.contains('invalid email') ||
        msg.contains('unable to validate email')) {
      return 'Please enter a valid email address.';
    }
    if (code == '429' ||
        msg.contains('too many requests') ||
        msg.contains('email rate limit exceeded')) {
      return 'Too many attempts. Please wait a few minutes and try again.';
    }
    if (msg.contains('otp expired') || msg.contains('token has expired')) {
      return 'Your verification link has expired. Please request a new one.';
    }
    if (msg.contains('session expired') || msg.contains('jwt expired')) {
      return 'Your session has expired. Please log in again.';
    }
    if (code == '500' || code == '503') {
      return 'Server error. Please try again later.';
    }

    return 'Authentication error: ${e.message}';
  }

  // ── Email Verification ─────────────────────────────
  Future<bool> verifyEmail(String email, String token) async {
    // Input validation
    if (email.isEmpty) {
      _setError('Email is required for verification');
      return false;
    }
    if (token.isEmpty) {
      _setError('Verification code is required');
      return false;
    }

    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.verifyEmail(email, token);
      _status = AuthStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      if (e is AuthException) {
        _setError(_mapAuthError(e));
      } else {
        _setError(
          'Email verification failed. Please check your code and try again.',
        );
      }
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
