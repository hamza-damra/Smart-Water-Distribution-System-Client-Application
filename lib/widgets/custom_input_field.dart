import 'package:flutter/material.dart';
import '../utilities/constants.dart';

class CustomInputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onEditPressed;

  const CustomInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.readOnly = false,
    this.onEditPressed,
  });

  @override
  State<CustomInputField> createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  // Helper method to replace deprecated withOpacity
  Color withValues(Color color, double opacity) => Color.fromRGBO(
    color.r.toInt(),
    color.g.toInt(),
    color.b.toInt(),
    opacity,
  );

  @override
  Widget build(BuildContext context) {
    // Determine keyboard type based on label if not explicitly provided
    final TextInputType keyboardType =
        widget.keyboardType ??
        (widget.label == 'Phone Number'
            ? TextInputType.phone
            : widget.label == 'Email Address'
            ? TextInputType.emailAddress
            : TextInputType.text);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                _isFocused
                    ? withValues(Constants.primaryColor, 0.2)
                    : withValues(Colors.black, 0.05),
            blurRadius: _isFocused ? 12 : 6,
            spreadRadius: _isFocused ? 1 : 0,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color:
              _isFocused
                  ? Constants.primaryColor
                  : withValues(Constants.primaryColor, 0.1),
          width: _isFocused ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.only(left: 16, right: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: withValues(
                Constants.primaryColor,
                _isFocused ? 0.15 : 0.08,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.icon,
              color: _isFocused ? Constants.primaryColor : Constants.greyColor,
              size: 20,
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: widget.controller,
              focusNode: _focusNode,
              readOnly: widget.readOnly,
              style: TextStyle(
                color:
                    widget.readOnly
                        ? Constants.greyColor
                        : Constants.blackColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                labelText: widget.label,
                labelStyle: TextStyle(
                  color:
                      _isFocused ? Constants.primaryColor : Constants.greyColor,
                  fontWeight: _isFocused ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 15,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                floatingLabelStyle: TextStyle(
                  color: Constants.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 8,
                ),
                filled: false,
              ),
              cursorColor: Constants.primaryColor,
              cursorWidth: 2,
              keyboardType: keyboardType,
            ),
          ),
          if (widget.readOnly && widget.onEditPressed != null)
            Container(
              margin: const EdgeInsets.only(right: 12),
              child: InkWell(
                onTap: widget.onEditPressed,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: withValues(Constants.accentColor, 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    color: Constants.primaryColor,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
