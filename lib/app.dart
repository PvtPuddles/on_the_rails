// @formatter:off
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/foundation.dart';
import 'package:on_the_rails/agents/user_agent.dart';
import 'package:on_the_rails/rails/bend.dart';
import 'package:on_the_rails/rails/rail.dart';
import 'package:on_the_rails/rails/straight.dart';
import 'package:on_the_rails/train/train.dart';
import 'package:on_the_rails/world.dart';
// @formatter:on

const trailingDistance = 80;

final _loop = [
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

final _figureEight = [
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

final _rails = _figureEight;

class OnTheRails extends FlameGame<RailWorld>
    with HasKeyboardHandlerComponents {
  OnTheRails() : super(world: RailWorld());

  @override
  Future<void> onLoad() async {
    await images.loadAll([
      ...allRails.map((e) => "rails/$e.png"),
      if (kDebugMode)
        ...[
          "rider",
          "rail_cell",
          "rail_cell_occupied",
          "rail_connection",
          "rail_segment_start",
        ].map((e) => "rails/debug/$e.png"),
    ]);

    camera.viewfinder.anchor = Anchor.center;

    final agent = UserAgent();
    world.add(agent);

    _addRails();
    final train = Train(
      agent: agent,
      cars: [
        TrainCar(length: 100, riderSpacing: 50, debugLabel: "first"),
        TrainCar.single(length: 50, debugLabel: "mid  "),
        TrainCar(length: 100, riderSpacing: 50, debugLabel: "last "),
      ],
    );
    train.rail = _rails.firstOrNull;
    world.add(train);
  }

  void _addRails() {
    for (final rail in _rails) {
      world.addRail(rail);
    }
  }
}
