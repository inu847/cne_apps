import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int? maxLines;
  final int? minLines;
  final bool readOnly;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final FocusNode? focusNode;
  final EdgeInsetsGeometry? contentPadding;
  final bool enabled;
  final bool autofocus;
  final bool enableInteractiveSelection;

  const CustomTextField({
    Key? key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.minLines,
    this.readOnly = false,
    this.suffixIcon,
    this.prefixIcon,
    this.focusNode,
    this.contentPadding,
    this.enabled = true,
    this.autofocus = false,
    this.enableInteractiveSelection = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      maxLines: maxLines,
      minLines: minLines,
      readOnly: readOnly,
      focusNode: focusNode,
      enabled: enabled,
      autofocus: autofocus,
      enableInteractiveSelection: enableInteractiveSelection,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
        contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1E2A78), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[200],
      ),
    );
  }
}

class CustomNumberTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool readOnly;
  final Widget? suffixIcon;
  final bool allowDecimal;
  final bool allowNegative;
  final FocusNode? focusNode;
  final EdgeInsetsGeometry? contentPadding;
  final bool enabled;
  final bool autofocus;
  final bool enableInteractiveSelection;

  const CustomNumberTextField({
    Key? key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.validator,
    this.onChanged,
    this.readOnly = false,
    this.suffixIcon,
    this.allowDecimal = false,
    this.allowNegative = false,
    this.focusNode,
    this.contentPadding,
    this.enabled = true,
    this.autofocus = false,
    this.enableInteractiveSelection = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(
        decimal: allowDecimal,
        signed: allowNegative,
      ),
      inputFormatters: [
        if (!allowDecimal && !allowNegative)
          FilteringTextInputFormatter.digitsOnly
        else if (!allowDecimal && allowNegative)
          FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
        if (allowDecimal)
          FilteringTextInputFormatter.allow(RegExp(allowNegative ? r'^-?\d*\.?\d*' : r'^\d*\.?\d*')),
      ],
      validator: validator,
      onChanged: onChanged,
      readOnly: readOnly,
      focusNode: focusNode,
      enabled: enabled,
      autofocus: autofocus,
      enableInteractiveSelection: enableInteractiveSelection,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        suffixIcon: suffixIcon,
        contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1E2A78), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[200],
      ),
    );
  }
}