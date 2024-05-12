// @formatter:off
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/foundation.dart';
import 'package:on_the_rails/rails/bend.dart';
import 'package:on_the_rails/rails/rail.dart';
import 'package:on_the_rails/rails/straight.dart';
import 'package:on_the_rails/rider.dart';
import 'package:on_the_rails/world.dart';
// @formatter:on

final _rails = {
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
};

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

    _addRails();
    final frontRunner = Rider(rail: _rails.last);
    world.add(frontRunner);
    final otherGuy = Rider(rail: _rails.last);
    otherGuy.distanceInRail -= 80;
    world.add(otherGuy);
  }

  void _addRails() {
    for (final rail in _rails) {
      world.addRail(rail);
    }
    // for (final entry in railMap.entries) {
    //   final rail = entry.value;
    //   if (kDebugMode && drawCells) {
    //     for (final cell in rail.shape) {
    //       bool isRailOrigin = cell.x == 0 && cell.y == 0;
    //       cell.rotate(rail.angle);
    //       cell.multiply(Vector2.all(cellSize));
    //       cell.add(rail.position);
    //       if (isRailOrigin) {
    //         world.add(RailCell.origin(position: cell, angle: rail.angle));
    //       } else {
    //         world.add(RailCell(position: cell));
    //       }
    //     }
    //   }
    //   world.add(rail);
    //   if (kDebugMode && drawPaths) {
    //     world.add(rail.startingConnection);
    //     world.add(rail.endingConnection);
    //   }
    // }
  }
}
