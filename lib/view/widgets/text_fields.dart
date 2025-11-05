import 'package:flutter/material.dart';
import 'package:staysafe/utils/app_colors.dart';
import 'package:staysafe/utils/text_style.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final IconData? icon;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;

  const CustomTextField({
    super.key,
    required this.hintText,
    this.icon,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: AppTextStyle.medium(color: Colors.black), // text inside field
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyle.regular(color: Colors.black54),
        prefixIcon: icon != null
            ? Icon(icon, color: AppColor.appPrimary)
            : null,
        filled: true,
        fillColor: AppColor.appSecondary, // background color inside field
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColor.appPrimary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColor.appPrimary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ),
      ),
    );
  }
}
