import 'package:flutter/material.dart';

class NewFeatureBadge extends StatelessWidget {
  final bool show;
  final String text;
  final double fontSize;
  final EdgeInsets padding;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;

  const NewFeatureBadge({
    super.key,
    this.show = true,
    this.text = 'NEW',
    this.fontSize = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    this.backgroundColor = Colors.red,
    this.textColor = Colors.white,
    this.borderColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
          letterSpacing: 0.5,
        ),
      ),
    );
  }
} 