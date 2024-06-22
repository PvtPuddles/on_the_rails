import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import 'package:on_the_rails/components/rails/shapes.dart';
import 'package:on_the_rails/world/world.dart';

part 'a_star.dart';

class PathBuilder {
  /// Straight rails, from longest to shortest
  ///
  /// (Straight, length)
  static final straights = [
    (Straight1.new, 1),
  ];

  /// 90 degree bends, from widest to leanest
  ///
  /// (Bend, (x distance, y distance))
  static final bends = [
    (Bend2x2.new, (2, 2)),
  ];

  static List<Rail> buildPathBetween(
    RailConnection start,
    RailConnection end, {
    RailWorld? world,
  }) {
    final rails = <Rail>[];

    final a = start.coord + start.rail.coord;
    final b = end.coord + end.rail.coord;

    final angleA = start.targetAngle % (2 * pi), angleB = end.angle % (2 * pi);

    // Straight line from A to B
    if ((a.x == b.x || a.y == b.y) && angleA == angleB) {
      // Naive, will not handle obstacles
      return lineFrom(a, to: b);
    }

    final delta = b - a;
    final omega = angleBetween(angleA, angleB);

    // L bend from a to b
    if (omega.abs() == pi / 2) {
      Bend smallestBend =
          PathBuilder.bends.first.$1.call(coord: CellCoord.zero, angle: angleA);
      if (omega > 0) smallestBend = smallestBend.flipped;
      final size = smallestBend.worldShape.size;
      if (delta.x.abs() >= size.x && delta.y.abs() >= size.y) {
        return bendFrom(a, angleA, to: b, toAngle: angleB);
      }
    }

    assert(false, "Hey, that shape isn't supported!");

    // TODO : U turns

    // TODO : Obstacle avoidance
    //  - Naive: Perform turn early if there is a blockage
    //  - Proper: Perform some type of depth-first search to find the first
    //    valid path. (Preferably re-using tracks along the way)

    return rails;
  }

  static double angleBetween(double a, double b) {
    a %= 2 * pi;
    b %= 2 * pi;
    final cw = (b - a) % (2 * pi);
    final ccw = (b - a - (2 * pi)).abs() % (2 * pi);
    if (cw <= ccw) return cw;
    return -ccw;
  }

  /// Draws a line connecting [start] to the given cellCoord, exclusive of both
  /// ends.
  static List<Rail> lineFrom(CellCoord start, {required CellCoord to}) {
    final rails = <Rail>[];

    assert(start.x == to.x || start.y == to.y);

    final angle =
        (Offset((to.x - start.x).toDouble(), (to.y - start.y).toDouble())
                .direction) %
            (2 * pi);
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

  static List<Rail> bendFrom(
    CellCoord start,
    double startAngle, {
    required CellCoord to,
    required double toAngle,
  }) {
    startAngle %= 2 * pi;
    toAngle %= 2 * pi;

    final delta = to - start;
    final omega = angleBetween(startAngle, toAngle);

    assert(omega.abs() == pi / 2, "L bends only!");

    CellCoord xStep = const CellCoord(1, 0) * delta.x.sign;
    CellCoord yStep = const CellCoord(0, 1) * delta.y.sign;

    // Known issue: this isn't likely to work on non-square bends, IE bends
    // whose shape depends on their rotation.  But hey, it might.
    final bends = PathBuilder.bends.map((e) => (e.$1, e.$2.rotate(startAngle)));
    final bendBuilder = bends.lastWhere((e) {
      return e.$2.$1 < delta.x.abs() && e.$2.$2 < delta.y.abs();
    });

    final bendWidth = bendBuilder.$2.$1.abs() - 1;
    final bendHeight = bendBuilder.$2.$2.abs() - 1;

    late CellCoord bendStart;

    // Go in x direction first
    if (startAngle % pi == 0) {
      final steps = (delta.x.abs() - bendBuilder.$2.$1.abs());
      bendStart = start + xStep * (steps + 1);
    }
    // Go in y direction first
    else {
      final steps = (delta.y.abs() - bendBuilder.$2.$2.abs());
      bendStart = start + yStep * (steps + 1);
    }

    Bend bend = bendBuilder.$1.call(coord: bendStart, angle: startAngle);
    var bendEnd = bendStart + (xStep * bendWidth) + (yStep * bendHeight);

    if (omega > 0) {
      bend = bend.flipped;
    }

    return [
      ...lineFrom(start, to: bendStart),
      bend,
      ...lineFrom(bendEnd, to: to)
    ];
  }
}

extension _RotateTuple on (int, int) {
  Vector2 get asVector => Vector2($1.toDouble(), $2.toDouble());

  (int, int) rotate(double angle, {(int, int)? center}) {
    final centerVector = center?.asVector;
    final rotated = asVector;
    rotated.rotate(angle, center: centerVector);
    return (rotated.x.round(), rotated.y.round());
  }
}
