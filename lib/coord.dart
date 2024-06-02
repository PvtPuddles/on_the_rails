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

  @override
  int get hashCode => Object.hashAll([x, y]);

  Vector2 toVector() => Vector2(x.toDouble(), y.toDouble());
  Offset toOffset() => Offset(x.toDouble(), y.toDouble());

  @override
  String toString() {
    return "($x, $y)";
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
}

extension VectorToCellCoord on Vector2 {
  CellCoord toCoord() => CellCoord(x.round(), y.round());
}

extension OffsetToCellCoord on Offset {
  CellCoord toCoord() => CellCoord(dx.round(), dy.round());
}
