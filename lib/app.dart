import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:on_the_rails/rails/bend.dart';
import 'package:on_the_rails/rails/rail.dart';
import 'package:on_the_rails/rails/straight.dart';

final _rails = {
  // Top bends
  Bend2x2(position: Vector2(-2, -2), angle: -pi / 2),
  Bend2x2(position: Vector2(0, -1)),

  // Right side
  Straight1x1(position: Vector2(0, 0)),
  Straight1x1(position: Vector2(0, 1)),

  // Bottom bends
  Bend2x2(position: Vector2(-1, 3), angle: pi / 2),
  Bend2x2(position: Vector2(-3, 2), angle: pi),

  // Left side
  Straight1x1(position: Vector2(-3, 0)),
  Straight1x1(position: Vector2(-3, 1)),
};

final railMap = Map<Vector2, Rail>.fromIterable(_rails,
    key: (rail) => rail.position,
    value: (rail) {
      final Vector2 position = rail.position;
      position.multiply(cellSize);
      rail.position = position;
      return rail;
    });

class OnTheRails extends FlameGame {
  OnTheRails();

  @override
  Future<void> onLoad() async {
    await images.loadAll([
      ...allRails.map((e) => "rails/$e.png"),
      if (kDebugMode)
        ...[
          "rail_cell",
          "rail_cell_occupied",
          "rail_segment_start",
        ].map((e) => "rails/debug/$e.png"),
    ]);

    camera.viewfinder.anchor = Anchor.center;

    _addRails();
  }

  void _addRails() {
    for (final entry in railMap.entries) {
      final rail = entry.value;
      if (kDebugMode) {
        for (final cell in rail.shape) {
          bool isRailOrigin = cell.x == 0 && cell.y == 0;
          cell.rotate(rail.angle);
          cell.multiply(cellSize);
          cell.add(rail.position);
          if (isRailOrigin) {
            world.add(RailCell.origin(position: cell));
          } else {
            world.add(RailCell(position: cell));
          }
        }
      }
      world.add(rail);
    }
  }
}
