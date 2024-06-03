import 'dart:math';
import 'dart:ui';

import 'package:on_the_rails/components/rails/shapes.dart';
import 'package:on_the_rails/coord.dart';

class PathBuilder {
  /// Straight rails, from longest to shortest
  static final straights = [
    (Straight1.new, 1),
  ];

  /// Bends, from widest to leanest
  static final bends = [
    (Bend2x2.new, (2, 2)),
  ];

  static List<Rail> buildPathBetween(RailConnection start, RailConnection end) {
    final rails = <Rail>[];

    final a = start.coord + start.rail.coord;
    final b = end.coord + end.rail.coord;

    if ((a.x == b.x || a.y == b.y) && start.targetAngle == end.angle) {
      return lineFrom(a, to: b);
    }

    assert(false, "We're only doing lines >:(");

    // TODO : L bends

    // TODO : U turns

    // TODO : Obstacle avoidance
    //  - Naive: Perform turn early if there is a blockage
    //  - Proper: Perform some type of depth-first search to find the first
    //    valid path.

    return rails;
  }

  /// Draws a line connecting [start] to the given cellCoord, exclusive of both
  /// ends.
  static List<Rail> lineFrom(CellCoord start, {required CellCoord to}) {
    final rails = <Rail>[];

    assert(start.x == to.x || start.y == to.y);

    final angle =
        Offset((to.x - start.x).toDouble(), (to.y - start.y).toDouble())
            .direction;
    assert(angle % (pi / 2) == 0);
    CellCoord step = const CellCoord(1, 0).rotate(angle);

    final deltaX = (to.x - start.x).abs();
    final deltaY = (to.y - start.y).abs();
    assert(deltaX == 0 || deltaY == 0);

    int pos = 1;
    final delta = deltaX == 0 ? deltaY : deltaX;
    while (pos < delta) {
      final builder =
          straights.firstWhere((builder) => builder.$2 <= (delta - pos));
      final rail = builder.$1(coord: start + (step * pos), angle: angle);
      rails.add(rail);
      pos += builder.$2;
    }

    return rails;
  }
}
