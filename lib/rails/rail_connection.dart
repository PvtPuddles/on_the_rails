import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:on_the_rails/components/arrow_component.dart';
import 'package:on_the_rails/priorities.dart';
import 'package:on_the_rails/rails/rail.dart';
import 'package:on_the_rails/world.dart';

class RailConnection extends SpriteComponent with HasGameReference {
  RailConnection(
    this.rail, {
    required double angle,
    required this.coord,
    required this.atRailStart,
  })  : _railDirection =
            (directionToCenter(rail, atRailStart) - angle) % (2 * pi),
        super(
          angle: angle % (2 * pi),
          size: Vector2.all(cellSize),
          anchor: Anchor.center,
          position: rail.position + coord.position,
          priority: Priority.rail - 2,
        ) {
    add(_DebugDirectionComponent(
      angle: _railDirection + rail.angle,
      color: Colors.green.withOpacity(.25),
      position: Vector2(0, cellSize) / 2,
      size: Vector2(
        4 * cellSize / 9,
        cellSize / 8,
      ),
      anchor: Anchor.centerLeft,
      priority: Priority.rail - 3,
    ));
  }

  final Rail rail;

  // Some jackass decided that rails should face upwards when rotated 0 degrees
  // Nvm, finally fixed it
  double get worldSpaceAngle => angle;

  /// Local-space direction the rail moves in.
  ///
  /// Relative to BOTH [angle] and [rail.angle].
  final double _railDirection;

  /// Global-space direction the rail moves in.
  double get railDirection => (_railDirection + rail.angle + angle) % (2 * pi);

  /// The cell the connection attaches to, relative to [rail]'s origin.
  final CellCoord coord;
  final bool atRailStart;

  // TODO : Lock switches so that they cannot be triggered while a train is
  //  traversing them
  late RailConnection? activeConnection = connections.firstOrNull;
  List<RailConnection> connections = [];

  void addConnection(RailConnection other) {
    final targetAngle = (angle - pi) % (2 * pi);
    assert(other.angle == targetAngle);

    connections.add(other);
    assert(
      connections.length <= 3,
      "There are only 3 directions; left, right, and neutral.",
    );
    if (connections.length > 1) {
      double relativeAngle(RailConnection connection) {
        double angle = connection.railDirection;
        // Connection angles are straddling 0
        if (this.angle == pi) {
          // Angle must be acute, otherwise none of this makes sense.
          assert(angle < pi / 2 || angle > 3 * pi / 2);
          // Connections at +315 should be converted to -45
          if (angle > pi) angle -= 2 * pi;
        }
        return angle;
      }

      connections.sortBy<Comparable<num>>(relativeAngle);
    }

    if (!other.connections.contains(this)) {
      other.addConnection(this);
    }
  }

  void setActive(int steering) {
    final straight = connections.firstWhereOrNull(
      (c) =>
          c._railDirection == (angle - pi) % (2 * pi) ||
          c._railDirection == angle,
    );

    switch (steering) {
      // Left-most
      case < 0:
        activeConnection = connections.first;
      // Right-most
      case > 0:
        activeConnection = connections.last;
      case 0 when straight != null:
        activeConnection = straight;
      case 0 when connections.length == 3:
        activeConnection = connections[1];
    }
  }

  @override
  void onLoad() {
    sprite = Sprite(game.images.fromCache("rails/debug/rail_connection.png"));
  }

  @override
  void render(Canvas canvas) {
    if (kDebugMode && drawPaths) {
      super.render(canvas);
    }
  }

  @override
  String toString() {
    return "${rail.runtimeType} @ ${rail.coord} (${atRailStart ? "S" : "E"})";
  }

  /// The direction from the start to the end of the rail, used for determining
  /// position in a junction.
  ///
  /// This function is agnostic to the rail's rotation
  @visibleForTesting
  static double directionToCenter(Rail rail, bool isAtStart) {
    late Offset start;
    final railLen = rail.metric.length;
    if (isAtStart) {
      start = rail.metric.getTangentForOffset(0)!.position;
    } else {
      start = rail.metric.getTangentForOffset(railLen)!.position;
    }
    final center = rail.metric.getTangentForOffset(railLen / 2)!.position;

    final delta = center - start;
    return delta.direction % (2 * pi);
  }
}

class _DebugDirectionComponent extends ArrowComponent {
  _DebugDirectionComponent({
    super.anchor,
    super.angle,
    super.color,
    super.position,
    super.priority,
    super.size,
  });

  @override
  void render(Canvas canvas) {
    if (kDebugMode && drawDirections) {
      super.render(canvas);
    }
  }
}

typedef ConnectionMap = Map<CellCoord, List<RailConnection>>;

extension ConnectionOps on ConnectionMap {
  addConnection(RailConnection connection) {
    final rail = connection.rail;
    final cCell = rail.coord + connection.coord;
    final cAngle = connection.worldSpaceAngle;
    _register(cCell, connection);
    // Offset by 1.4 so that if we have diagonal rails in the future, they'll
    // round up, while cardinal rails will round down.
    final targetOffset =
        cCell.toOffset() + Offset.fromDirection(cAngle - pi, 1.4);
    final targetCell = targetOffset.toCoord();
    final partnerAngle = (connection.worldSpaceAngle - pi) % (2 * pi);
    final partners = this[targetCell]?.where((p) {
      return p.worldSpaceAngle == partnerAngle;
    });

    if (partners != null) {
      for (final partner in partners) {
        connection.addConnection(partner);
      }
    }
  }

  void _register(CellCoord key, RailConnection value) {
    if (containsKey(key)) {
      this[key]!.add(value);
    } else {
      this[key] = [value];
    }
  }
}
