import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:on_the_rails/rails/rail.dart';
import 'package:on_the_rails/rails/rail_connection.dart';

const double cellSize = 128;

class RailWorld extends World {
  RailWorld();

  Map<CellCoord, List<Rail>> rails = {};

  Map<CellCoord, List<RailConnection>> connections = {};

  void addRail(Rail rail) {
    // Add debug cells to world
    if (kDebugMode) {
      for (final cell in rail.shape) {
        bool isRailOrigin = cell.x == 0 && cell.y == 0;
        cell.rotate(rail.angle);
        cell.multiply(Vector2.all(cellSize));
        cell.add(rail.position);
        if (isRailOrigin) {
          add(RailCell.origin(position: cell, angle: rail.angle));
        } else {
          add(RailCell(position: cell));
        }
      }
    }

    // Add rail itself
    rails.register(rail.coord, rail);
    add(rail);

    connections.addConnection(rail.startingConnection);
    add(rail.startingConnection);
    connections.addConnection(rail.endingConnection);
    add(rail.endingConnection);
  }
}

extension Register<K, T> on Map<K, List<T>> {
  void register(K key, T value) {
    if (containsKey(key)) {
      this[key]!.add(value);
    } else {
      this[key] = [value];
    }
  }
}

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

  Vector2 get position => toVector() * cellSize;

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
