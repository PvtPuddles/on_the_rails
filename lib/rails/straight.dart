import 'dart:math';

import 'package:flame/components.dart';

import 'rail.dart';

const rails = [
  "straight1x1",
];

class Straight1x1 extends Rail {
  Straight1x1({
    required super.position,
    super.angle,
  })  : assert(
          angle == null || angle % (pi / 2) == 0,
        ),
        super(
          name: rails[0],
          shape: [
            Vector2(0, 0),
          ],
        );

  /// Local-space path describing this rail
  @override
  Path get path {
    final Path path = Path();
    Vector2 start = Vector2(cellSize / 2, 0);
    Vector2 end = Vector2(cellSize / 2, cellSize);

    path.moveTo(start.x, start.y);
    path.lineTo(end.x, end.y);
    return path;
  }
}
