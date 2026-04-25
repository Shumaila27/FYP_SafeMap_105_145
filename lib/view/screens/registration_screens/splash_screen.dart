import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../utils/app_colors.dart';
import '../../widgets/buttons.dart';
import 'main_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: double.infinity,
            height: 700.h,
            decoration: BoxDecoration(
              color: AppColor.appPrimary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(150), // curved top-left corner
                topRight: Radius.circular(150), // curved top-right corner
              ),
            ),
            child: Column(
              children: [
                SizedBox(height: 100.h),
                ClipOval(
                  child: Image.asset(
                    "assets/logo.png",
                    height: 250.h, // your height
                    width: 200.w, // your width
                    fit: BoxFit
                        .cover, // ensures it covers the circle without distortion
                  ),
                ),
                //Text("logo here",style: TextStyle(color: Colors.black,fontSize: 24.sp),),
                SizedBox(height: 150.h),
                CustomButton(
                  text: "Get Started",
                  textColor: Colors.white,
                  buttonColor: AppColor.appSecondary,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MainScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
