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
  @override
  Widget build(BuildContext context) {
    // Controllers
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final phoneController = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const AuthHeader(),

              Text(
                'Create Account',
                style: AppTextStyle.bold(color: AppColor.appSecondary),
              ),
              SizedBox(height: 10.h),
              Text(
                'Sign up to get started',
                style: AppTextStyle.semiBold(color: AppColor.appSecondary),
              ),
              SizedBox(height: 30.h),

              // Name Field
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: CustomTextField(
                  hintText: "Full Name",
                  icon: Icons.person_outline,
                  controller: nameController,
                  keyboardType: TextInputType.name,
                ),
              ),
              SizedBox(height: 20.h),

              // Email Field
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: CustomTextField(
                  hintText: "Email",
                  icon: Icons.email_outlined,
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              SizedBox(height: 20.h),

              // Phone Field
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: CustomTextField(
                  hintText: "Phone Number",
                  icon: Icons.phone_outlined,
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                ),
              ),
              SizedBox(height: 20.h),

              // Password field
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: CustomTextField(
                  hintText: "Password",
                  icon: Icons.lock_outline,
                  controller: passwordController,
                  isPassword: true,
                ),
              ),
              SizedBox(height: 20.h),

              // Confirm Password field
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: CustomTextField(
                  hintText: "Confirm Password",
                  icon: Icons.lock_outline,
                  controller: confirmPasswordController,
                  isPassword: true,
                ),
              ),

              SizedBox(height: 30.h),

              // Sign Up Button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: CustomButton(
                  text: "Sign Up",
                  buttonColor: AppColor.appSecondary,
                  textColor: Colors.white,
                  onPressed: () {
                    // TODO: Implement signup logic
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                ),
              ),
              SizedBox(height: 30.h),

              // OR Continue with Google
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[500], thickness: 2)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: Text(
                      "or continue with",
                      style: AppTextStyle.medium(color: Colors.black),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[500], thickness: 2)),
                ],
              ),
              SizedBox(height: 8.h),

              // Google Button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Add Google sign-up action
                  },
                  icon: Container(
                    height: 28.h,
                    width: 28.w,
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
                      fontSize: 15.sp,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    elevation: 6,
                    shadowColor: Colors.grey.withOpacity(0.3),
                    backgroundColor: Colors.white,
                    surfaceTintColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(35.r),
                      side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.w),
                  ).copyWith(
                    overlayColor: WidgetStatePropertyAll(
                      Colors.grey.withOpacity(0.1),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 10.h),

              // Login Redirect
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
    );
  }
}