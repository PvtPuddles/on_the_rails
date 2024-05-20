import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class ArrowComponent extends CustomPainterComponent {
  ArrowComponent({
    super.position,
    super.size,
    super.priority,
    super.angle,
    super.anchor,
    Color? color,
  }) : super(painter: _ArrowPainter(color: color));
}

class _ArrowPainter extends CustomPainter {
  _ArrowPainter({this.color});

  final Color? color;

  @override
  void paint(Canvas canvas, Size size) {
    const stemRatio = 1;
    final stemWidth = size.height * stemRatio;
    final center = Point<double>(size.width / 2, size.height / 2);

    final top = center.y - stemWidth / 2;
    final bottom = center.y + stemWidth / 2;
    final arrow = Path()
      ..moveTo(0, top)
      ..lineTo(size.width - stemWidth / 2, top)
      ..lineTo(size.width, center.y)
      ..lineTo(size.width - stemWidth / 2, bottom)
      ..lineTo(0, bottom);

    final paint = Paint()..color = color ?? Colors.green;

    canvas.drawPath(arrow, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
