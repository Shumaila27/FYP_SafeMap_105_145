import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTextStyle {
  // Bold Text Style
  static TextStyle bold({Color color = Colors.black}) {
    return TextStyle(
      fontSize: 20.sp, // responsive
      fontWeight: FontWeight.bold,
      color: color,
      fontFamily: 'Poppins',
    );
  }

  // Semi-Bold Text Style
  static TextStyle semiBold({Color color = Colors.black}) {
    return TextStyle(
      fontSize: 18.sp,
      fontWeight: FontWeight.w600,
      color: color,
      fontFamily: 'Poppins',
    );
  }

  // Medium Text Style
  static TextStyle medium({Color color = Colors.black}) {
    return TextStyle(
      fontSize: 16.sp,
      fontWeight: FontWeight.w500,
      color: color,
      fontFamily: 'Poppins',
    );
  }

  // Regular Text Style
  static TextStyle regular({Color color = Colors.black}) {
    return TextStyle(
      fontSize: 14.sp,
      fontWeight: FontWeight.w400,
      color: color,
      fontFamily: 'Poppins',
    );
  }

  // Light Text Style
  static TextStyle light({Color color = Colors.black54}) {
    return TextStyle(
      fontSize: 12.sp,
      fontWeight: FontWeight.w300,
      color: color,
      fontFamily: 'Poppins',
    );
  }
}
