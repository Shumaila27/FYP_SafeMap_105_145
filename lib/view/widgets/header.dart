import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/app_colors.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 150.h, // responsive height
      child: Stack(
        children: [
          // 🔹 Light color background (slightly lower to peek from bottom)
          Positioned(
            top: 20.h, // 👈 Adjust this for how much light color shows
            left: 0,
            right: 0,
            child: Container(
              width: double.infinity,
              height: 90.h,
              decoration: BoxDecoration(
                color: AppColor.appPrimary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(150),
                  bottomRight: Radius.circular(150),
                ),
              ),
            ),
          ),

          // 🔹 Dark color container (placed on top)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              width: double.infinity,
              height: 80.h,
              decoration: BoxDecoration(
                color: AppColor.appSecondary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(150),
                  bottomRight: Radius.circular(150),
                ),
              ),
            ),
          ),
        ],
      ),
    );

  }
}
