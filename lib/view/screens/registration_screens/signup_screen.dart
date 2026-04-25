import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:staysafe/view/screens/registration_screens/login_screen.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/text_style.dart';
import '../../widgets/buttons.dart';
import '../../widgets/header.dart';
import '../../widgets/text_fields.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                          Column(
                            children: [
                              Text(
                                'Create Account',
                                style: AppTextStyle.bold(color: AppColor.appSecondary),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Sign up to get started',
                                style: AppTextStyle.semiBold(color: AppColor.appSecondary),
                              ),
                            ],
                          ),
                          CustomTextField(
                            hintText: "Full Name",
                            icon: Icons.person_outline,
                            controller: nameController,
                            keyboardType: TextInputType.name,
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) return "Name is required";
                              return null;
                            },
                          ),
                          SizedBox(height: vGap),
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
                          SizedBox(height: vGap),
                          CustomTextField(
                            hintText: "Phone Number",
                            icon: Icons.phone_outlined,
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) return "Phone number is required";
                              return null;
                            },
                          ),
                          SizedBox(height: vGap),
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
                          SizedBox(height: vGap),
                          CustomTextField(
                            hintText: "Confirm Password",
                            icon: Icons.lock_outline,
                            controller: confirmPasswordController,
                            isPassword: true,
                            validator: (value) {
                              if ((value ?? '').isEmpty) return "Please confirm password";
                              if (value != passwordController.text) return "Passwords do not match";
                              return null;
                            },
                          ),
                          CustomButton(
                            text: "Sign Up",
                            buttonColor: AppColor.appSecondary,
                            textColor: Colors.white,
                            onPressed: () {
                              if (!_formKey.currentState!.validate()) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Signup frontend validated. Backend signup will be added next."),
                                ),
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
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
                                  content: Text("Google sign-up will be available after backend integration."),
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
                                "Already have an account?",
                                style: AppTextStyle.regular(color: Colors.black87),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const LoginScreen()),
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