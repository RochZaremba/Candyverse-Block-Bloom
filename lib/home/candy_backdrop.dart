import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Original quiet candy-paper scenery; stays behind meaningful controls.
class CandyBackdrop extends StatelessWidget {
  const CandyBackdrop({required this.theme, required this.child, super.key});
  final AppTheme theme;
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.color('bubblegumPink'),
              theme.color('creamWhite'),
              theme.color('turquoise').withValues(alpha: .25),
            ],
          ),
        ),
      ),
      IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(painter: _BackdropPainter(theme)),
        ),
      ),
      child,
    ],
  );
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter(this.theme);
  final AppTheme theme;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = theme.color('creamWhite').withValues(alpha: .5);
    for (var i = 0; i < 7; i++) {
      final center = Offset(
        size.width * ((i * .37 + .07) % 1),
        size.height * (.06 + i * .13),
      );
      canvas.drawOval(
        Rect.fromCenter(center: center, width: 86, height: 22),
        paint,
      );
      canvas.drawCircle(center + const Offset(-14, -10), 19, paint);
      canvas.drawCircle(center + const Offset(10, -9), 23, paint);
    }
    for (var i = 0; i < 24; i++) {
      final center = Offset(
        size.width * ((i * .618) % 1),
        size.height * ((i * .381 + .1) % 1),
      );
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(i * math.pi / 5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-3, -1, 6, 2),
          const Radius.circular(1),
        ),
        Paint()..color = theme.color('ink').withValues(alpha: .08),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) =>
      theme != oldDelegate.theme;
}
