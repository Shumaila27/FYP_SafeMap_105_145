import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget{

  //initializing variables
  final String text;
  final Color textColor;
  final Color buttonColor;
  final VoidCallback? onPressed;
  final double fontSize;

  //constructor
  const CustomButton({
    super.key,
    required this.text,
    required this.textColor,
    required this.buttonColor,
    this.onPressed,
    this.fontSize = 18,
  });

  @override
  Widget build(BuildContext context){
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(text,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }



}