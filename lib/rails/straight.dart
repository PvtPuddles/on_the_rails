import 'dart:math';

import 'package:flame/components.dart';
import 'package:on_the_rails/rails/rail_connection.dart';
import 'package:on_the_rails/world.dart';

import 'rail.dart';

const rails = [
  "straight1x1",
];

class Straight1x1 extends _Straight {
  Straight1x1({
    super.key,
    required super.coord,
    super.angle,
  })  : assert(
          angle == null || angle % (pi / 2) == 0,
        ),
        super(name: rails[0], length: 1);
}

abstract class _Straight extends Rail {
  _Straight({
    super.key,
    required super.name,
    required super.coord,
    List<Vector2>? shape,
    super.angle,
    required this.length,
  }) : super(
            shape: shape ??
                [
                  for (int i = 0; i < length; i++) Vector2(i.toDouble(), 0),
                ]);

  final int length;

  @override
  late final startingConnection = RailConnection(
    this,
    angle: angle,
    coord: CellCoord.zero,
    atRailStart: true,
  );

  @override
  late final RailConnection endingConnection = RailConnection(
    this,
    angle: angle + pi,
    coord: CellCoord.zero,
    atRailStart: false,
  );

  @override
  Path buildPath() {
    final Path path = Path();
    Vector2 start = Vector2(0, cellSize / 2);
    Vector2 end = Vector2(length * cellSize, cellSize / 2);

    path.moveTo(start.x, start.y);
    path.lineTo(end.x, end.y);
    return path;
  }
}
