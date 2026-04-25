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
  @override
  Widget build(BuildContext context) {
    // ✅ Controllers
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
        backgroundColor: Colors.white,
      body:SafeArea(
          child:  SingleChildScrollView(
            child: Column(
              children: [

                const AuthHeader(),

                Text(
                  'Welcome Back',
                  style: AppTextStyle.bold(color: AppColor.appSecondary, ),
                ),
                SizedBox(height: 10.h),
                Text(
                  'Login to your account',
                  style: AppTextStyle.semiBold(color: AppColor.appSecondary, ),
                ),
                SizedBox(height: 30.h),
                //Email Field
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

                // Password field with eye toggle
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: CustomTextField(
                    hintText: "Password",
                    icon: Icons.lock_outline,
                    controller: passwordController,
                    isPassword: true, // 👁️ enables the eye toggle
                  ),
                ),

                SizedBox(height: 5.h),

// 🔹 Forgot Password Text
                Padding(
                  padding: EdgeInsets.only(right: 24.w),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Navigate to Forget Password Screen
                      },
                      child: Text(
                        "Forgot Password?",
                        style: AppTextStyle.medium(
                          color: AppColor.appSecondary,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20.h),

                // 🔹 Login Button (Customizable)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: CustomButton(
                    text: "Login",
                    buttonColor: AppColor.appSecondary,
                    textColor: Colors.white,
                    onPressed: () {
                      Navigator.push(
                        context,
                        //MaterialPageRoute(builder: (context) => const LoginScreen()),
                        MaterialPageRoute(builder: (context) => DashBoardScreen()),//for trying we have placed otherwise login to signup
                      );
                    },
                  ),
                ),
                SizedBox(height: 30.h),

                // 🔹 OR Continue with Google
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

                // 🔹 Google Button
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Add Google sign-in action
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
                      elevation: 6, // soft shadow for depth
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
                        Colors.grey.withOpacity(0.1), // soft tap ripple
                      ),
                    ),
                  ),
                ),


                SizedBox(height:10.h),

                // 🔹 Register Redirect
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
      )

    );
  }
}
