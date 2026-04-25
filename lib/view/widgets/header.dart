import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/app_colors.dart';

/// ✅ Custom Painter that draws a wavy header
class WavyHeaderPainter extends CustomPainter {
  final Color color;

  WavyHeaderPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    // ✅ Start from top-left
    path.lineTo(0, size.height * 0.40);

    // ✅ First wave curve
    path.quadraticBezierTo(
      size.width * 0.15,
      size.height * 0.80,
      size.width * 0.5,
      size.height * 0.55,
    );

    // ✅ Second wave curve
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.10,
      size.width,
      size.height * 0.55,
    );

    // ✅ Close shape
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// ✅ Main Auth Header Widget (with optional back button)
class AuthHeader extends StatelessWidget {
  final bool showBackButton;
  final double? height;
  final double? topWaveHeight;

  const AuthHeader({
    super.key,
    this.showBackButton = true,
    this.height,
    this.topWaveHeight,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height ?? 180.h,
      child: Stack(
        children: [
          // ✅ Light wave (background)
          Positioned.fill(
            child: CustomPaint(
              painter: WavyHeaderPainter(AppColor.appPrimary),
            ),
          ),

          // ✅ Dark wave (top layer)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: topWaveHeight ?? 150.h,
              child: CustomPaint(
                painter: WavyHeaderPainter(AppColor.appSecondary),
              ),
            ),
          ),

          // ✅ Back Button (visible if true)
          if (showBackButton)
            Positioned(
              top: 30.h,
              left: 15.w,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  Icons.arrow_back,
                  size: 28.sp,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
