import 'dart:math';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  final List<_Particle> particles = [];

  static const _pastelColors = [kPrimary, kMint, kCoral, kAmber];

  @override
  void initState() {
    super.initState();
    controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 12))
          ..repeat();

    final random = Random();
    for (int i = 0; i < 22; i++) {
      particles.add(_Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 7 + 3,
        speed: random.nextDouble() * 0.0015 + 0.0008,
        colorIndex: random.nextInt(_pastelColors.length),
      ));
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return CustomPaint(
          painter: _ParticlePainter(particles, controller.value),
          child: widget.child,
        );
      },
    );
  }
}

class _Particle {
  double x, y, size, speed;
  int colorIndex;
  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.colorIndex,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  static const _pastelColors = [kPrimary, kMint, kCoral, kAmber];

  _ParticlePainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()
        ..color = _pastelColors[p.colorIndex].withOpacity(0.20);
      final dy = (p.y + progress * p.speed * 10) % 1;
      canvas.drawCircle(
        Offset(p.x * size.width, dy * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}