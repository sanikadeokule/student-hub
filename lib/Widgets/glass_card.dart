import 'dart:ui';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final Color color;

  const GlassCard({super.key, required this.child, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? color.withOpacity(0.25)
                : color.withOpacity(0.65),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(isDark ? 0.12 : 0.30),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(isDark ? 0.15 : 0.25),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: DefaultTextStyle(
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            child: IconTheme(
              data: const IconThemeData(color: Colors.white),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}