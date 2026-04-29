import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:staysafe/view/screens/settings_screen.dart';
import '../../utils/text_style.dart';

class AppMainBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBack; // ✅ NEW: Show back button or not

  const AppMainBar({
    super.key,
    this.showBack = false, // ✅ Default: false
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppBar(
      backgroundColor: colorScheme.primary,
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.25),

      automaticallyImplyLeading: false,

      // ✅ Back Button + Logo + Name
      title: Row(
        children: [
          // ✅ Back Button (only when showBack = true)
          if (showBack)
            IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: colorScheme.onPrimary,
                size: 26.sp,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),

          if (showBack) SizedBox(width: 55.w),

          // ✅ Logo
          ClipOval(
            child: Image.asset(
              "assets/logo.png",
              height: 45.h, // your height
              width: 36.w, // your width
              fit: BoxFit
                  .cover, // ensures it covers the circle without distortion
            ),
          ),

          SizedBox(width: 10.w),

          // ✅ App Name
          Text("SafeMap", style: AppTextStyle.bold(color: colorScheme.onPrimary)),
        ],
      ),

      // ✅ Settings Icon
      actions: [
        IconButton(
          icon: Icon(Icons.settings, color: colorScheme.onPrimary, size: 28.sp),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(60.h);
}
