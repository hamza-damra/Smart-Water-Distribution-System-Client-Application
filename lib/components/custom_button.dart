import 'package:flutter/material.dart';
import 'package:mytank/utilities/constants.dart';
import 'package:mytank/components/custom_text.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final MediaQueryData mediaQueryData;
  final double width;
  final VoidCallback? onPressed;
  
  const CustomButton(
    this.text, {
    super.key,
    required this.mediaQueryData,
    required this.width,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        alignment: Alignment.center,
        height: mediaQueryData.size.height * 0.07,
        width: width,
        decoration: BoxDecoration(
          color: Constants.primaryColor,
          borderRadius: BorderRadius.circular(mediaQueryData.size.height * 0.03),
        ),
        child: CustomText(
          text,
          fontColor: Constants.whiteColor,
          fontSize: mediaQueryData.size.height * 0.025,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
