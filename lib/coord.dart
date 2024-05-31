import 'dart:ui';

import 'package:flame/game.dart';
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

  @override
  int get hashCode => Object.hashAll([x, y]);

  Vector2 toVector() => Vector2(x.toDouble(), y.toDouble());
  Offset toOffset() => Offset(x.toDouble(), y.toDouble());

  @override
  String toString() {
    return "($x, $y)";
  }
}

extension VectorToCellCoord on Vector2 {
  CellCoord toCoord() => CellCoord(x.round(), y.round());
}

extension OffsetToCellCoord on Offset {
  CellCoord toCoord() => CellCoord(dx.round(), dy.round());
}
