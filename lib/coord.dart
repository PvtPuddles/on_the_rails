import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/foundation.dart';

@immutable
class CellCoord {
  static const zero = CellCoord(0, 0);

  const CellCoord(this.x, this.y);

  final int x;
  final int y;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CellCoord) return false;
    return x == other.x && y == other.y;
  }

  CellCoord operator +(CellCoord other) {
    return CellCoord(x + other.x, y + other.y);
  }

  CellCoord operator -(CellCoord other) {
    return CellCoord(x - other.x, y - other.y);
  }

  CellCoord operator -() {
    return CellCoord(-x, -y);
  }

  CellCoord operator *(int scalar) {
    return CellCoord(x * scalar, y * scalar);
  }

  CellCoord abs() {
    return CellCoord(x.abs(), y.abs());
  }

  @override
  int get hashCode => Object.hashAll([x, y]);

  Vector2 toVector() => Vector2(x.toDouble(), y.toDouble());
  Offset toOffset() => Offset(x.toDouble(), y.toDouble());

  @override
  String toString() {
    return "($x, $y)";
  }

  /// Rotates the [CellCoord] with [angle] in radians
  /// rotates around [center] if it is defined
  /// In a screen coordinate system (where the y-axis is flipped) it rotates in
  /// a clockwise fashion
  /// In a normal coordinate system it rotates in a counter-clockwise fashion
  CellCoord rotate(double angle, {CellCoord? center}) {
    int x = this.x;
    int y = this.y;
    if ((x == 0 && y == 0) || angle == 0) {
      // No point in rotating the zero coord or to rotate with 0 as angle
      return this;
    }
    late int newX;
    late int newY;
    if (center == null) {
      newX = (x * cos(angle) - y * sin(angle)).round();
      newY = (x * sin(angle) + y * cos(angle)).round();
    } else {
      newX =
          (cos(angle) * (x - center.x) - sin(angle) * (y - center.y) + center.x)
              .round();
      newY =
          (sin(angle) * (x - center.x) + cos(angle) * (y - center.y) + center.y)
              .round();
    }
    return CellCoord(newX, newY);
  }
}

class CellShape {
  const CellShape(this.cells);

  static const unit = CellShape([CellCoord.zero]);

  final List<CellCoord> cells;

  (CellCoord, CellCoord) get bounds {
    final minX = cells.map((e) => e.x).min;
    final maxX = cells.map((e) => e.x).max;
    final minY = cells.map((e) => e.y).min;
    final maxY = cells.map((e) => e.y).max;
    return (CellCoord(minX, minY), CellCoord(maxX, maxY));
  }

  Vector2 get size {
    final (min, max) = bounds;
    return Vector2((max.x - min.x) + 1, (max.y - min.y) + 1);
  }

  Vector2 get center {
    return Vector2(size.x / 2, size.y / 2);
  }

  Anchor get anchor {
    assert(cells.any((cell) => cell.x == 0 && cell.y == 0));
    final (min, max) = bounds;
    // Relative position of x=0 from bounds.start
    final xValue = -min.x;
    final domain = (max.x - min.x) + 1;
    // Relative position of y=0 from bounds.start
    final yValue = -min.y;
    final range = (max.y - min.y) + 1;

    final x = xValue / domain;
    final y = yValue / range; // Center

    final anchorPos = Vector2(x + .5 / domain, y + .5 / range);
    return Anchor(anchorPos.x, anchorPos.y);
  }

  Vector2 get origin {
    final size = this.size;
    final x = anchor.x * size.x;
    final y = anchor.y * size.y;
    return Vector2(x, y);
  }

  CellShape transform(CellCoord origin, {double angle = 0}) {
    final cells = <CellCoord>[];
    for (final cell in this.cells) {
      final v2 = cell.toVector();
      v2.rotate(angle);
      cells.add(v2.toCoord() + origin);
    }
    return CellShape(cells);
  }
}

extension VectorToCellCoord on Vector2 {
  CellCoord toCoord() => CellCoord(x.round(), y.round());
}

extension OffsetToCellCoord on Offset {
  CellCoord toCoord() => CellCoord(dx.round(), dy.round());
}
