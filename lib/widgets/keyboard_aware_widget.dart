import 'package:flutter/material.dart';

class KeyboardAwareWidget extends StatelessWidget {
  final Widget child;
  final bool maintainBottomViewPadding;
  final EdgeInsets? padding;
  final bool resizeToAvoidBottomInset;

  const KeyboardAwareWidget({
    Key? key,
    required this.child,
    this.maintainBottomViewPadding = false,
    this.padding,
    this.resizeToAvoidBottomInset = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: padding ?? EdgeInsets.only(
        bottom: isKeyboardVisible && !resizeToAvoidBottomInset 
            ? keyboardHeight 
            : 0,
      ),
      child: MediaQuery(
        data: mediaQuery.copyWith(
          viewInsets: resizeToAvoidBottomInset 
              ? mediaQuery.viewInsets 
              : EdgeInsets.zero,
        ),
        child: child,
      ),
    );
  }
}

class PerformantTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool obscureText;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final InputDecoration? decoration;
  final TextStyle? style;
  final bool autocorrect;
  final bool enableSuggestions;
  final bool enableInteractiveSelection;
  final FocusNode? focusNode;
  final bool autofocus;

  const PerformantTextField({
    Key? key,
    this.controller,
    this.hintText,
    this.labelText,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.prefixIcon,
    this.suffixIcon,
    this.decoration,
    this.style,
    this.autocorrect = false,
    this.enableSuggestions = false,
    this.enableInteractiveSelection = false,
    this.focusNode,
    this.autofocus = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        obscureText: obscureText,
        enabled: enabled,
        maxLines: maxLines,
        minLines: minLines,
        autocorrect: autocorrect,
        enableSuggestions: enableSuggestions,
        enableInteractiveSelection: enableInteractiveSelection,
        style: style,
        decoration: decoration ?? InputDecoration(
          hintText: hintText,
          labelText: labelText,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class PerformantTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String? initialValue;
  final String? hintText;
  final String? labelText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldValidator<String>? validator;
  final bool obscureText;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final InputDecoration? decoration;
  final TextStyle? style;
  final bool autocorrect;
  final bool enableSuggestions;
  final bool enableInteractiveSelection;

  const PerformantTextFormField({
    Key? key,
    this.controller,
    this.initialValue,
    this.hintText,
    this.labelText,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onFieldSubmitted,
    this.validator,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.prefixIcon,
    this.suffixIcon,
    this.decoration,
    this.style,
    this.autocorrect = false,
    this.enableSuggestions = false,
    this.enableInteractiveSelection = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: TextFormField(
        controller: controller,
        initialValue: initialValue,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onChanged: onChanged,
        onFieldSubmitted: onFieldSubmitted,
        validator: validator,
        obscureText: obscureText,
        enabled: enabled,
        maxLines: maxLines,
        minLines: minLines,
        autocorrect: autocorrect,
        enableSuggestions: enableSuggestions,
        enableInteractiveSelection: enableInteractiveSelection,
        style: style,
        decoration: decoration ?? InputDecoration(
          hintText: hintText,
          labelText: labelText,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}