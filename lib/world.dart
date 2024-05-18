import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:on_the_rails/rails/rail.dart';

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

    for (final connection in [rail.startingConnection, rail.endingConnection]) {
      _registerConnection(connection, rail);
    }
  }

  void _registerConnection(RailConnection connection, Rail rail) {
    final cCell = rail.coord + connection.coord;
    final cAngle = connection.worldSpaceAngle;
    connections.register(cCell, connection);
    // Offset by 1.4 so that if we have diagonal rails in the future, they'll
    // round up, while cardinal rails will round down.
    final targetOffset =
        cCell.toOffset() + Offset.fromDirection(cAngle - pi, 1.4);
    final targetCell = targetOffset.toCoord();
    final partnerAngle = (connection.worldSpaceAngle - pi) % (2 * pi);
    final partner = connections[targetCell]?.firstWhereOrNull((p) {
      return p.worldSpaceAngle == partnerAngle;
    });

    if (partner != null) {
      partner.connections.add(connection);
      connection.connections.add(partner);
    }

    if (kDebugMode) add(connection);
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
