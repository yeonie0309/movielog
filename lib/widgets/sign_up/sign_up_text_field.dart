import 'package:flutter/material.dart';

class SignUpTextField extends StatelessWidget {
  const SignUpTextField({
    super.key,
    required this.fieldKey,
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.validator,
    required this.onChanged,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
    this.suffixIcon,
    this.onFieldSubmitted,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final String? Function(String?) validator;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
