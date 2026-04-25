import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/text_style.dart';
import '../../widgets/buttons.dart';
import '../../widgets/header.dart';
import 'login_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Column(
          children: [

            // ✅ Fixed header stays same height
            const AuthHeader(),

            // ✅ Main content adapts automatically to screen height
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),

                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly, // ✅ auto spacing
                  crossAxisAlignment: CrossAxisAlignment.center,

                  children: [
                    Text(
                      "SafeMap",
                      style: AppTextStyle.bold(color: AppColor.appSecondary),
                    ),

                    Text(
                      "Stay Safe With SafeMap!",
                      style: AppTextStyle.medium(color: AppColor.appSecondary),
                    ),

                    // ✅ Auto-resizing logo
                    Flexible(
                      flex: 2,
                      child: Image.asset(
                        "assets/logo.png",
                        height: 120.h,
                        width: 120.w,
                        fit: BoxFit.contain,
                      ),
                    ),

                    // ✅ Subtitle
                    Text(
                      "Your AI Safety Companion",
                      style: AppTextStyle.medium(color: AppColor.appSecondary),
                    ),
                    // ✅ Flexible spacing
                    SizedBox(height: 5,),
                    // const Spacer(),
                    // ✅ Buttons (auto adjust)
                    Column(
                      children: [
                        CustomButton(
                          text: "Login",
                          textColor: Colors.white,
                          buttonColor: AppColor.appSecondary,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                          },
                        ),
                        SizedBox(height: 15.h),

                        CustomButton(
                          text: "Sign Up",
                          textColor: Colors.black,
                          buttonColor: AppColor.appSecondary,
                        ),
                      ],
                    ),

                    SizedBox(height: 20.h), // ✅ small responsive padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
