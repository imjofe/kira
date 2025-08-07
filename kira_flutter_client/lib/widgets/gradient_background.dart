import 'package:flutter/material.dart';
import 'package:kira_flutter_client/theme/app_theme.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: skyDawnGradient),
      child: child,
    );
  }
}