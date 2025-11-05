import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget{

  //initializing variables
  final String text;
  final Color textColor;
  final Color buttonColor;
  final VoidCallback? onPressed;

  //constructor
  const CustomButton({
    super.key,
    required this.text,
    required this.textColor,
    required this.buttonColor,
    this.onPressed,
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
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }



}