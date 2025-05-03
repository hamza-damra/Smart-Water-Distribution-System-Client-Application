import 'package:flutter/material.dart';
import 'package:mytank/utilities/constants.dart';

class CustomIconContainer extends StatelessWidget {
  final String imgPath;
  final MediaQueryData mediaQueryData;
  final VoidCallback? onTap;
  
  const CustomIconContainer({
    super.key,
    required this.imgPath,
    required this.mediaQueryData,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 92,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Constants.primaryColor,
        ),
        child: Image.asset(imgPath),
      ),
    );
  }
}
