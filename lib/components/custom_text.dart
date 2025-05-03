import 'package:flutter/material.dart';
import 'package:mytank/utilities/constants.dart';

class CustomText extends StatelessWidget {
  final double fontSize;
  final FontWeight fontWeight;
  final Color fontColor;
  final String text;
  final TextAlign textAlign;
  final String fontFamily;
  
  const CustomText(
    this.text, {
    super.key,
    this.fontSize = 40,
    this.fontWeight = FontWeight.w200,
    this.fontColor = Constants.primaryColor,
    this.textAlign = TextAlign.center,
    this.fontFamily = "Roboto",
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: fontColor,
        fontFamily: fontFamily,
      ),
    );
  }
}
