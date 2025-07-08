import 'package:flutter/material.dart';

/// A simple loading indicator widget that shows a centered circular progress indicator
class LoadingIndicator extends StatelessWidget {
  /// Creates a loading indicator with optional size and color
  const LoadingIndicator({
    Key? key,
    this.size = 40.0,
    this.color,
  }) : super(key: key);

  /// The size of the circular progress indicator
  final double size;
  
  /// The color of the circular progress indicator. If null, uses the theme's primary color
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: CircularProgressIndicator(
        strokeWidth: 4.0,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}