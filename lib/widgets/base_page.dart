import 'package:flutter/material.dart';

class BasePage extends StatelessWidget {
  final Widget child;
  final bool showBannerAd;

  const BasePage({
    super.key,
    required this.child,
    this.showBannerAd = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: child),
        ],
      ),
    );
  }
} 