import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/app_colors.dart';
import '../../utils/text_style.dart';
import '../widgets/buttons.dart'; // ✅ For your customizable button
import '../widgets/header.dart';
import '../widgets/text_fields.dart';
import 'home_page.dart'; // ✅ Import your CustomTextField

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Controllers
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔹 Reusable Header
            const AuthHeader(),

            //SizedBox(height: 0.h),

            // 🔹 Welcome Text
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

            // 🔹 Email Field
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

            // 🔹 Password Field
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: CustomTextField(
                hintText: "Password",
                icon: Icons.lock_outline,
                controller: passwordController,
                obscureText: true,
              ),
            ),

            SizedBox(height: 30.h),

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
                    MaterialPageRoute(builder: (context) => const SafeSpotHomeScreen()),//for trying we have placed otherwise login to signup
                  );
                },
              ),
            ),
            SizedBox(height: 50.h),

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
            SizedBox(height: 10.h),

            // 🔹 Google Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: ElevatedButton.icon(
                onPressed: () {
                  // Google login action here
                },
                icon: Image.asset(
                  'assets/logo/google-logo.webp', // add your Google logo
                  height: 50.h,
                  width: 50.w,
                ),
                label: Text(
                  "Continue with Google",
                  style: AppTextStyle.regular(color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
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
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
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
    );
  }
}
