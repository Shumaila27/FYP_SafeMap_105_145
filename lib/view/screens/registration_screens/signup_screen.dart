// lib/view/screens/registrat.../signup_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:staysafe/view/screens/registration_screens/login_screen.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/text_style.dart';
import '../../widgets/buttons.dart';
import '../../widgets/header.dart';
import '../../widgets/text_fields.dart';
import '../../../Controller/auth_provider.dart';
import '../../../Models/auth_model.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  late final TextEditingController confirmPasswordController;
  late final TextEditingController phoneController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
    phoneController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  // ── Signup Handler ────────────────────────────────────
  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    final signupModel = SignupModel(
      fullName: nameController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text,
      phone: phoneController.text.trim(),
    );

    final success = await authProvider.signup(signupModel);

    if (!mounted) return;

    if (success) {
      // Show success message then go to login
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Account created! Please check your email to verify your account.',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Signup failed'),
          backgroundColor: Colors.red,
        ),
      );
      authProvider.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool compact = constraints.maxHeight < 840;
            final double vGap = compact ? 10.h : 14.h;

            return Form(
              key: _formKey,
              child: Column(
                children: [
                  AuthHeader(
                    height: compact ? 110.h : 150.h,
                    topWaveHeight: compact ? 88.h : 120.h,
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // ── Title ──────────────────────────────────
                          Column(
                            children: [
                              Text(
                                'Create Account',
                                style: AppTextStyle.bold(
                                  color: AppColor.appSecondary,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Sign up to get started',
                                style: AppTextStyle.semiBold(
                                  color: AppColor.appSecondary,
                                ),
                              ),
                            ],
                          ),

                          // ── Full Name Field ────────────────────────
                          CustomTextField(
                            hintText: "Full Name",
                            icon: Icons.person_outline,
                            controller: nameController,
                            keyboardType: TextInputType.name,
                            validator: (value) {
                              final input = value ?? '';
                              final nameError = SignupModel(
                                fullName: input,
                                email: '',
                                password: '',
                                phone: '',
                              ).validateFullName();
                              return nameError;
                            },
                          ),
                          SizedBox(height: vGap),

                          // ── Email Field ────────────────────────────
                          CustomTextField(
                            hintText: "Email",
                            icon: Icons.email_outlined,
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              final input = value?.trim() ?? '';
                              final emailError = SignupModel(
                                fullName: '',
                                email: input,
                                password: '',
                                phone: '',
                              ).validateEmail();
                              return emailError;
                            },
                          ),
                          SizedBox(height: vGap),

                          // ── Phone Field ────────────────────────────
                          CustomTextField(
                            hintText: "Phone Number",
                            icon: Icons.phone_outlined,
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              final input = value ?? '';
                              final phoneError = SignupModel(
                                fullName: '',
                                email: '',
                                password: '',
                                phone: input,
                              ).validatePhone();
                              return phoneError;
                            },
                          ),
                          SizedBox(height: vGap),

                          // ── Password Field ─────────────────────────
                          CustomTextField(
                            hintText: "Password",
                            icon: Icons.lock_outline,
                            controller: passwordController,
                            isPassword: true,
                            validator: (value) {
                              final input = value ?? '';
                              final passwordError = SignupModel(
                                fullName: '',
                                email: '',
                                password: input,
                                phone: '',
                              ).validatePassword();
                              return passwordError;
                            },
                          ),
                          SizedBox(height: vGap),

                          // ── Confirm Password Field ─────────────────
                          CustomTextField(
                            hintText: "Confirm Password",
                            icon: Icons.lock_outline,
                            controller: confirmPasswordController,
                            isPassword: true,
                            validator: (value) {
                              if ((value ?? '').isEmpty) {
                                return "Please confirm password";
                              }
                              if (value != passwordController.text) {
                                return "Passwords do not match";
                              }
                              return null;
                            },
                          ),

                          // ── Signup Button (with loading state) ─────
                          Consumer<AuthProvider>(
                            builder: (context, auth, _) {
                              return auth.isLoading
                                  ? const CircularProgressIndicator()
                                  : CustomButton(
                                      text: "Sign Up",
                                      buttonColor: AppColor.appSecondary,
                                      textColor: Colors.white,
                                      onPressed: _handleSignup,
                                    );
                            },
                          ),

                          // ── Divider (hidden on compact screens) ────
                          if (!compact)
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey[500],
                                    thickness: 1.5,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                  ),
                                  child: Text(
                                    "or continue with",
                                    style: AppTextStyle.medium(
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey[500],
                                    thickness: 1.5,
                                  ),
                                ),
                              ],
                            ),

                          // ── Google Button ──────────────────────────
                          ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Google sign-up will be available after backend integration.",
                                  ),
                                ),
                              );
                            },
                            icon: Container(
                              height: 26.h,
                              width: 26.w,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: Image.asset(
                                'assets/logo/google-logo.webp',
                                fit: BoxFit.contain,
                              ),
                            ),
                            label: Text(
                              "Google",
                              style:
                                  AppTextStyle.regular(
                                    color: colorScheme.onSurface,
                                  ).copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14.sp,
                                  ),
                            ),
                            style:
                                ElevatedButton.styleFrom(
                                  elevation: 4,
                                  shadowColor: Colors.grey.withValues(
                                    alpha: 0.3,
                                  ),
                                  backgroundColor:
                                      colorScheme.surfaceContainerLowest,
                                  surfaceTintColor:
                                      colorScheme.surfaceContainerLowest,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(35.r),
                                    side: const BorderSide(
                                      color: Color(0xFFE0E0E0),
                                      width: 1,
                                    ),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    vertical: 10.h,
                                    horizontal: 14.w,
                                  ),
                                ).copyWith(
                                  overlayColor: WidgetStatePropertyAll(
                                    Colors.grey.withValues(alpha: 0.1),
                                  ),
                                ),
                          ),

                          // ── Login Row ──────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Already have an account?",
                                style: AppTextStyle.regular(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  "Login",
                                  style: AppTextStyle.bold(
                                    color: AppColor.appSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
