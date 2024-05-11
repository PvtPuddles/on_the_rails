// @formatter:Off
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/foundation.dart';
import 'package:on_the_rails/rails/bend.dart';
import 'package:on_the_rails/rails/rail.dart';
import 'package:on_the_rails/rails/straight.dart';
import 'package:on_the_rails/rider.dart';
// @formatter:on

const double cellSize = 128;

final _rails = {
  // Top bends
  Bend2x2(position: Vector2(-2, -2), angle: -pi / 2),
  Straight1x1(position: Vector2(-1, -2), angle: pi / 2),
  Bend2x2(position: Vector2(1, -1)),

  // Right side
  Straight1x1(position: Vector2(1, 0)),
  Straight1x1(position: Vector2(1, 1)),

  // Bottom bends
  Bend2x2(position: Vector2(0, 3), angle: pi / 2),
  Straight1x1(position: Vector2(-1, 3), angle: pi / 2),
  Bend2x2(position: Vector2(-3, 2), angle: pi),

  // Left side
  Straight1x1(position: Vector2(-3, 0)),
  Straight1x1(position: Vector2(-3, 1)),
};

final railMap = Map<Vector2, Rail>.fromIterable(_rails,
    key: (rail) => rail.position,
    value: (rail) {
      final Vector2 position = rail.position;
      position.multiply(Vector2.all(cellSize));
      rail.position = position;
      return rail;
    });

class OnTheRails extends FlameGame with HasKeyboardHandlerComponents {
  OnTheRails();

  @override
  Future<void> onLoad() async {
    await images.loadAll([
      ...allRails.map((e) => "rails/$e.png"),
      if (kDebugMode)
        ...[
          "rider",
          "rail_cell",
          "rail_cell_occupied",
          "rail_segment_start",
        ].map((e) => "rails/debug/$e.png"),
    ]);

    camera.viewfinder.anchor = Anchor.center;

    _addRails();
    world.add(Rider(rail: railMap.values.first));
  }

  void _addRails() {
    for (final entry in railMap.entries) {
      final rail = entry.value;
      if (kDebugMode && drawCells) {
        for (final cell in rail.shape) {
          bool isRailOrigin = cell.x == 0 && cell.y == 0;
          cell.rotate(rail.angle);
          cell.multiply(Vector2.all(cellSize));
          cell.add(rail.position);
          if (isRailOrigin) {
            world.add(RailCell.origin(position: cell, angle: rail.angle));
          } else {
            world.add(RailCell(position: cell));
          }
        }
      }
      world.add(rail);
    }
  }
}
