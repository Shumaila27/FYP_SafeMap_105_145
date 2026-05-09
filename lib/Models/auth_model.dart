// lib/Models/auth_model.dart

class AuthModel {
  final String email;
  final String password;

  AuthModel({required this.email, required this.password});

  // ── Validation Methods ──────────────────────────────
  String? validateEmail() {
    if (email.trim().isEmpty) {
      return "Email is required";
    }
    if (!email.contains('@')) {
      return "Enter a valid email";
    }
    if (!email.contains('.')) {
      return "Enter a valid email";
    }
    return null;
  }

  String? validatePassword() {
    if (password.trim().isEmpty) {
      return "Password is required";
    }
    if (password.length < 8) {
      return "Password must be at least 8 characters";
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return "Password must contain uppercase letter";
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return "Password must contain number";
    }
    return null;
  }
}

class SignupModel {
  final String fullName;
  final String email;
  final String password;
  final String phone;

  SignupModel({
    required this.fullName,
    required this.email,
    required this.password,
    required this.phone,
  });

  // ── Validation Methods ──────────────────────────────
  String? validateFullName() {
    if (fullName.trim().isEmpty) {
      return "Full name is required";
    }
    if (fullName.length < 3) {
      return "Name must be at least 3 characters";
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(fullName)) {
      return "Name can only contain letters and spaces";
    }
    return null;
  }

  String? validateEmail() {
    if (email.trim().isEmpty) {
      return "Email is required";
    }
    if (!email.contains('@')) {
      return "Enter a valid email";
    }
    if (!email.contains('.')) {
      return "Enter a valid email";
    }
    return null;
  }

  String? validatePassword() {
    if (password.trim().isEmpty) {
      return "Password is required";
    }
    if (password.length < 8) {
      return "Password must be at least 8 characters";
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return "Password must contain uppercase letter";
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return "Password must contain number";
    }
    return null;
  }

  String? validatePhone() {
    if (phone.trim().isEmpty) {
      return "Phone number is required";
    }
    if (!RegExp(r'^[\d\s\-\+\(\)]+$').hasMatch(phone)) {
      return "Enter a valid phone number";
    }
    if (phone.replaceAll(RegExp(r'[^\d]'), '').length < 10) {
      return "Phone number must be at least 10 digits";
    }
    return null;
  }
}
