// lib/view/screens/registrat.../login_screen.dart

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:staysafe/view/screens/dashboard.dart';
import 'signup_screen.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/text_style.dart';
import '../../widgets/buttons.dart';
import '../../widgets/header.dart';
import '../../widgets/text_fields.dart';
import '../../../Controller/auth_provider.dart';
import '../../../Controller/map_controller.dart';
import '../../../Models/auth_model.dart';
import '../../../services/fcm_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController emailController;
  late final TextEditingController passwordController;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ── Login Handler ─────────────────────────────────────
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    final authModel = AuthModel(
      email: emailController.text.trim(),
      password: passwordController.text,
    );

    final success = await authProvider.login(authModel);

    if (!mounted) return;

    if (success) {
      // Save FCM token first so notifications reach this device
      await FCMService.instance.saveTokenToSupabase();
      
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login successful! Welcome back!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      // Navigate directly to Dashboard and clear navigation stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DashBoardScreen()),
        (route) => false,
      );
      // Check if this user is a guardian for an active Safe Walk.
      // Delay allows MapController.init() to finish first.
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        context.read<MapController>().refreshTrackedWalk();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Login failed'),
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
            final bool compact = constraints.maxHeight < 760;

            return Form(
              key: _formKey,
              child: Column(
                children: [
                  AuthHeader(
                    height: compact ? 120 : 160,
                    topWaveHeight: compact ? 95 : 130,
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // ── Title ──────────────────────────────────
                          Column(
                            children: [
                              Text(
                                'Welcome Back',
                                style: AppTextStyle.bold(
                                  color: AppColor.appSecondary,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Login to your account',
                                style: AppTextStyle.semiBold(
                                  color: AppColor.appSecondary,
                                ),
                              ),
                            ],
                          ),

                          // ── Email Field ────────────────────────────
                          CustomTextField(
                            hintText: "Email",
                            icon: Icons.email_outlined,
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              final input = value?.trim() ?? '';
                              final emailError = AuthModel(
                                email: input,
                                password: '',
                              ).validateEmail();
                              return emailError;
                            },
                          ),

                          // ── Password Field ─────────────────────────
                          CustomTextField(
                            hintText: "Password",
                            icon: Icons.lock_outline,
                            controller: passwordController,
                            isPassword: true,
                            validator: (value) {
                              final input = value ?? '';
                              final passwordError = AuthModel(
                                email: '',
                                password: input,
                              ).validatePassword();
                              return passwordError;
                            },
                          ),

                          // ── Forgot Password ────────────────────────
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Forgot password flow will be added with backend auth.",
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                "Forgot Password?",
                                style: AppTextStyle.medium(
                                  color: AppColor.appSecondary,
                                ),
                              ),
                            ),
                          ),

                          // ── Login Button (with loading state) ──────
                          Consumer<AuthProvider>(
                            builder: (context, auth, _) {
                              return auth.isLoading
                                  ? const CircularProgressIndicator()
                                  : CustomButton(
                                      text: "Login",
                                      buttonColor: AppColor.appSecondary,
                                      textColor: Colors.white,
                                      onPressed: _handleLogin,
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
                                    horizontal: 10,
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
                                    "Google sign-in will be available after backend integration.",
                                  ),
                                ),
                              );
                            },
                            icon: Container(
                              height: 26,
                              width: 26,
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
                                    fontSize: 14,
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
                                    borderRadius: BorderRadius.circular(35),
                                    side: const BorderSide(
                                      color: Color(0xFFE0E0E0),
                                      width: 1,
                                    ),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 14,
                                  ),
                                ).copyWith(
                                  overlayColor: WidgetStatePropertyAll(
                                    Colors.grey.withValues(alpha: 0.1),
                                  ),
                                ),
                          ),

                          // ── Register Row ───────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account?",
                                style: AppTextStyle.regular(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SignupScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  "Register",
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
