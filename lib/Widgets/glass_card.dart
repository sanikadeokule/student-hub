import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final Color color;

  const GlassCard({super.key, required this.child, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            /// Main card background with higher opacity for visibility
            color: color.withOpacity(0.55),
            borderRadius: BorderRadius.circular(16),
            /// Soft border for definition
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 1.5,
            ),
            /// Subtle shadow for depth
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          /// Ensure child content (icon and text) is visible
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