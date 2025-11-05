import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/app_colors.dart';
import '../../utils/text_style.dart';
import '../widgets/buttons.dart';
import '../widgets/header.dart';
import 'login_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 🔹 Reusable Header
          const AuthHeader(),

          // 🔹 Customizable Content Area
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              child: Column(
                //crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Stay Safe!",
                    style: AppTextStyle.bold(color:AppColor.appSecondary),
                  ),
                  SizedBox(height: 20.h),
                  Image.asset(
                    "assets/logo/img.png",
                    height: 100.h,
                    width: 80.w,
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    "Your AI safety Companion",
                    style: AppTextStyle.bold(color:AppColor.appSecondary),
                  ),
                  SizedBox(height: 50.h),
                  CustomButton(
                    text: "Login",
                    textColor: Colors.white,
                    buttonColor: AppColor.appSecondary,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                  ),
                  SizedBox(height: 20.h),
                  CustomButton(
                    text: "Sign Up",
                    textColor: Colors.white,
                    buttonColor: AppColor.appSecondary,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MainScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
