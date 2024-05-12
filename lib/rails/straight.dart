import 'dart:math';

import 'package:flame/components.dart';
import 'package:on_the_rails/world.dart';

import 'rail.dart';

const rails = [
  "straight1x1",
];

class Straight1x1 extends Rail {
  Straight1x1({
    required super.coord,
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

  @override
  late final startingConnection = RailConnection(
    this,
    angle: angle,
    coord: CellCoord.zero,
    atRailStart: true,
  );
  @override
  late final endingConnection = RailConnection(
    this,
    angle: angle + pi,
    coord: CellCoord.zero,
    atRailStart: false,
  );

  @override
  Path buildPath() {
    final Path path = Path();
    Vector2 start = Vector2(0, cellSize / 2);
    Vector2 end = Vector2(cellSize, cellSize / 2);

    path.moveTo(start.x, start.y);
    path.lineTo(end.x, end.y);
    return path;
  }
}
