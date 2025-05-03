import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final bool obscure;
  final MediaQueryData mediaQueryData;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  
  const CustomTextField({
    super.key,
    required this.label,
    this.obscure = false,
    required this.mediaQueryData,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.controller,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: mediaQueryData.size.width * 0.9,
      height: mediaQueryData.size.height * 0.063,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        keyboardType: keyboardType,
        onChanged: onChanged,
      ),
    );
  }
}
