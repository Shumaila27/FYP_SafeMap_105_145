import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:staysafe/view/screens/dashboard.dart';
import 'signup_screen.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/text_style.dart';
import '../../widgets/buttons.dart'; // ✅ For your customizable button
import '../../widgets/header.dart';
import '../../widgets/text_fields.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool compact = constraints.maxHeight < 760;
            return Form(
              key: _formKey,
              child: Column(
                children: [
                  AuthHeader(
                    height: compact ? 120.h : 160.h,
                    topWaveHeight: compact ? 95.h : 130.h,
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Text(
                                'Welcome Back',
                                style: AppTextStyle.bold(color: AppColor.appSecondary),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                'Login to your account',
                                style: AppTextStyle.semiBold(color: AppColor.appSecondary),
                              ),
                            ],
                          ),
                          CustomTextField(
                            hintText: "Email",
                            icon: Icons.email_outlined,
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              final input = value?.trim() ?? '';
                              if (input.isEmpty) return "Email is required";
                              if (!input.contains('@')) return "Enter a valid email";
                              return null;
                            },
                          ),
                          CustomTextField(
                            hintText: "Password",
                            icon: Icons.lock_outline,
                            controller: passwordController,
                            isPassword: true,
                            validator: (value) {
                              final input = value ?? '';
                              if (input.isEmpty) return "Password is required";
                              if (input.length < 6) return "Password must be at least 6 characters";
                              return null;
                            },
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Forgot password flow will be added with backend auth."),
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
                          CustomButton(
                            text: "Login",
                            buttonColor: AppColor.appSecondary,
                            textColor: Colors.white,
                            onPressed: () {
                              if (!_formKey.currentState!.validate()) {
                                return;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const DashBoardScreen()),
                              );
                            },
                          ),
                          if (!compact)
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.grey[500], thickness: 1.5)),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                                  child: Text(
                                    "or continue with",
                                    style: AppTextStyle.medium(color: Colors.black),
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.grey[500], thickness: 1.5)),
                              ],
                            ),
                          ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Google sign-in will be available after backend integration."),
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
                              style: AppTextStyle.regular(
                                color: Colors.black,
                              ).copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.sp,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              elevation: 4,
                              shadowColor: Colors.grey.withOpacity(0.3),
                              backgroundColor: Colors.white,
                              surfaceTintColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(35.r),
                                side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 14.w),
                            ).copyWith(
                              overlayColor: WidgetStatePropertyAll(
                                Colors.grey.withOpacity(0.1),
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account?",
                                style: AppTextStyle.regular(color: Colors.black87),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const SignupScreen()),
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
