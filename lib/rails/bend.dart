import 'dart:math';

import 'package:flame/components.dart';
import 'package:on_the_rails/rails/rail.dart';

const rails = [
  "bend2x2",
];

class Bend2x2 extends Rail {
  Bend2x2({required super.position, super.angle})
      : assert(
          angle == null || angle % (pi / 2) == 0,
        ),
        super(
          name: rails[0],
          shape: [
            Vector2(0, 0),
            Vector2(-1, -1),
          ],
        );

  static const imageSize = 32;

  /// The number of margin before the arc starts in the PNG image
  static const arcMargin = (4 / imageSize) * cellSize;

  @override
  Path get path {
    final Path path = Path();
    final start = Vector2((1.5) * cellSize, (2) * cellSize);
    final arcStart = Vector2(start.x, start.y - arcMargin);
    final end = Vector2((0) * cellSize, (.5) * cellSize);
    final arcEnd = Vector2(end.x + arcMargin, end.y);

    /// Bends are circular
    final radius = Radius.circular(arcEnd.x - arcStart.x);

    path.moveTo(start.x, start.y);
    path.lineTo(arcStart.x, arcStart.y);
    path.arcToPoint(Offset(arcEnd.x, arcEnd.y),
        radius: radius, clockwise: false);
    path.lineTo(end.x, end.y);

    return path;
  }
}
