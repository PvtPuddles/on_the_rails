import 'dart:math';

import 'package:on_the_rails/rails/straight.dart';
import 'package:on_the_rails/world.dart';

import 'bend.dart';

abstract final class Layouts {
  static final test = [
    Straight1x1(coord: const CellCoord(0, 1), angle: pi),
    Bend2x2(coord: const CellCoord(0, 2)),

    // T
    Straight1x1(coord: const CellCoord(0, -1), angle: pi / 2),
    Straight1x1(coord: const CellCoord(0, 0), angle: pi / 2),
    Bend2x2(coord: const CellCoord(0, -2), angle: -pi / 2),
    Bend2x2(coord: const CellCoord(1, -3), angle: -pi),
  ];

  static final loop = [
    // Top bends
    Bend2x2(coord: const CellCoord(-1, -2), angle: pi),
    Straight1x1(coord: const CellCoord(0, -2), angle: pi),
    Bend2x2(coord: const CellCoord(2, -1), angle: -pi / 2),

    // Right side
    Straight1x1(coord: const CellCoord(2, 0), angle: pi / 2),
    Straight1x1(coord: const CellCoord(2, 1), angle: pi / 2),

    // Bottom bends
    Bend2x2(coord: const CellCoord(1, 3), angle: 0),
    Straight1x1(coord: const CellCoord(0, 3), angle: pi),
    Bend2x2(coord: const CellCoord(-2, 2), angle: pi / 2),

    // Left side
    Straight1x1(coord: const CellCoord(-2, 0), angle: pi / 2),
    Straight1x1(coord: const CellCoord(-2, 1), angle: pi / 2),
  ];

  static final figureEight = [
    // Horizontal
    Straight1x1(coord: const CellCoord(-1, 0), angle: 0),
    Straight1x1(coord: const CellCoord(0, 0), angle: 0),
    Straight1x1(coord: const CellCoord(1, 0), angle: 0),

    // Top right
    Bend2x2(coord: const CellCoord(2, 0), angle: 0),
    Bend2x2(coord: const CellCoord(3, -2), angle: -pi / 2),
    Bend2x2(coord: const CellCoord(1, -3), angle: -pi),

    // Vertical
    Straight1x1(coord: const CellCoord(0, -1), angle: pi / 2),
    Straight1x1(coord: const CellCoord(0, 0), angle: pi / 2),
    Straight1x1(coord: const CellCoord(0, 1), angle: pi / 2),

    // Bottom left
    Bend2x2(coord: const CellCoord(-2, 0), angle: pi),
    Bend2x2(coord: const CellCoord(-3, 2), angle: pi / 2),
    Bend2x2(coord: const CellCoord(-1, 3), angle: 0),
  ];

  static final clover = [
    ...figureEight,

    // Top Left
    Bend2x2(coord: const CellCoord(-3, -1), angle: -3 * pi / 2),
    Bend2x2(coord: const CellCoord(-2, -3), angle: -pi),
    Bend2x2(coord: const CellCoord(0, -2), angle: -pi / 2),

    // Bottom Right
    Bend2x2(coord: const CellCoord(3, 1), angle: 3 * pi / 2),
    Bend2x2(coord: const CellCoord(2, 3), angle: 0),
    Bend2x2(coord: const CellCoord(0, 2), angle: pi / 2),
  ];

  static final cloverPlus = [
    ...clover,
    for (int x = 0; x < 3; x++) Straight1x1(coord: CellCoord(-1 + x, -3)),
    for (int x = 0; x < 3; x++) Straight1x1(coord: CellCoord(-1 + x, 3)),
    for (int y = 0; y < 3; y++)
      Straight1x1(coord: CellCoord(-3, -1 + y), angle: pi / 2),
    for (int y = 0; y < 3; y++)
      Straight1x1(coord: CellCoord(3, -1 + y), angle: pi / 2),
    Bend2x2(coord: const CellCoord(-1, 0)),
    Bend2x2(coord: const CellCoord(0, -1), angle: pi / 2),
    Bend2x2(coord: const CellCoord(1, 0), angle: pi),
    Bend2x2(coord: const CellCoord(0, 1), angle: 3 * pi / 2),
  ];
}
