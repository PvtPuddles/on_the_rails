import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:on_the_rails/components/rails/rail.dart';
import 'package:on_the_rails/world/world.dart';

import 'rail_connection.dart';

const rails = [
  "bend2x2",
];

/// A bent rail.
///
/// Bends should always bend in the negative direction;
/// - In UI-Space (+y axis down): to the left
/// - In Cartesian space (+y axis up): to the right
///
/// Since the sprite is rendered in UI space, make sure that the bend sprite
/// curves to the left.
class Bend2x2 extends Bend {
  Bend2x2({
    super.key,
    required super.coord,
    super.angle,
  })  : assert(
          angle == null || angle % (pi / 2) == 0,
        ),
        super(
          name: rails[0],
          shape: const CellShape([
            CellCoord(0, 0),
            CellCoord(1, -1),
          ]),
        );

  static const imageSize = 32;

  /// The amount of margin before the arc starts in the PNG image
  static const arcMargin = (4 / imageSize) * cellSize;

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
    angle: angle + (pi / 2),
    coord: (const CellCoord(1, -1).toVector()..rotate(angle)).toCoord(),
    atRailStart: false,
  );

  @override
  Bend get flipped {
    return Bend2x2(
      coord: coord -
          endingConnection.coord.rotate(-(pi / 2), center: CellCoord.zero),
      angle: (angle - (pi / 2)) % (2 * pi),
    );
  }

  @override
  Path buildPath() {
    return pathTemplate();
  }

  static Path pathTemplate() {
    final Path path = Path();
    final start = Vector2(0, 1.5) * cellSize;
    final arcStart = Vector2(start.x + arcMargin, start.y);
    final end = Vector2(1.5, 0) * cellSize;
    final arcEnd = Vector2(end.x, end.y + arcMargin);

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

abstract class Bend extends Rail {
  Bend({
    super.key,
    required super.name,
    required super.shape,
    required super.coord,
    super.angle,
  });

  Bend get flipped;
}
