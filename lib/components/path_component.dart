import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:on_the_rails/priorities.dart';

class PathComponent extends PositionComponent {
  PathComponent(
    this.path, {
    Paint? paint,
    required super.position,
  })  : _paint = (paint ?? Paint()
          ..color = Colors.red
          ..strokeWidth = 2)
          ..style = PaintingStyle.stroke,
        super(
          priority: Priority.rail - 1,
          size: _sizeOf(path),
        );

  final Path path;
  final Paint _paint;

  @override
  void render(Canvas canvas) {
    canvas.drawPath(path, _paint);
  }

  static Vector2 _sizeOf(Path path) {
    final bounds = path.getBounds();
    return Vector2(bounds.width, bounds.height);
  }
}
