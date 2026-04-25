import 'package:flutter/material.dart';

class CustomBadge extends StatelessWidget {
  final String text;
  final Color color;
  final Color fontColor;
  final double fontSize;
  final EdgeInsets padding;
  final double borderRadius;
  final bool outlined;

  const CustomBadge({
    super.key,
    required this.text,
    required this.color,
    this.fontColor = Colors.white,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.borderRadius = 8,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color,
        borderRadius: BorderRadius.circular(borderRadius),
        border: outlined ? Border.all(color: color, width: 1.5) : null,
      ),
      child: Text(
        text,
        style: TextStyle(color: fontColor, fontSize: fontSize, fontWeight: FontWeight.bold),
      ),
    );
  }
}
