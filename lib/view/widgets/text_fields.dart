import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:staysafe/utils/text_style.dart';

class CustomTextField extends StatefulWidget {
  final String hintText;
  final IconData? icon;
  final TextEditingController? controller;
  final bool isPassword; // ✅ To toggle eye visibility only for password fields
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.hintText,
    this.icon,
    this.controller,
    this.isPassword = false, // ✅ default false for normal text fields
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true; // ✅ Used only if isPassword = true

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword ? _obscureText : false, // ✅ Toggle dots
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      style: AppTextStyle.medium(color: colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: AppTextStyle.regular(
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        ),

        // ✅ Prefix icon (like email or lock)
        prefixIcon: widget.icon != null
            ? Icon(widget.icon, color: colorScheme.primary)
            : null,

        // ✅ Eye toggle icon (only for password fields)
        suffixIcon: widget.isPassword
            ? IconButton(
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
          icon: Icon(
            _obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: colorScheme.primary,
          ),
        )
            : null,

        filled: true,
        fillColor: colorScheme.surface, // Background color

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.r),
          borderSide: BorderSide(color: colorScheme.primary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.r),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 3,
          ),
        ),
        contentPadding:
        EdgeInsets.symmetric(horizontal: 20.h, vertical: 15),
      ),
    );
  }
}
