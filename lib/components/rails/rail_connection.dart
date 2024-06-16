import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:on_the_rails/components/arrow_component.dart';
import 'package:on_the_rails/components/rails/rail.dart';
import 'package:on_the_rails/priorities.dart';
import 'package:on_the_rails/world/world.dart';

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

  /// The [RailConnection] at the other end of the [rail].
  late final RailConnection partner = this == rail.startingConnection
      ? rail.endingConnection
      : rail.startingConnection;

  // /// The direction the rail connection is facing out there in the real world,
  // /// taking rail's rotation into account.
  // double get worldSpaceAngle => (angle - rail.angle) % (2 * pi);
  //
  // /// The direction the rail connection is facing out there in the real world,
  // /// taking rail's rotation into account.
  // double get worldSpaceTarget => (worldSpaceAngle - pi) % (2 * pi);

  /// The angle pointing out of the rail through this connection.
  double get targetAngle => (angle - pi) % (2 * pi);

  /// The cell this connection is targeting.
  CellCoord get targetCell =>
      (coord + rail.coord) + const CellCoord(1, 0).rotate(targetAngle);

  /// Local-space direction the rail moves in.
  ///
  /// Relative to BOTH [angle] and [rail.angle].
  final double _railDirection;

  /// Global-space direction the rail moves in.
  double get railDirection => (_railDirection + rail.angle + angle) % (2 * pi);

  /// The cell the connection attaches to, relative to [rail]'s origin.
  final CellCoord coord;
  final bool atRailStart;

  late RailConnection? _activeConnection = connections.firstOrNull;

  RailConnection? get activeConnection => _activeConnection;

  set activeConnection(RailConnection? value) {
    _activeConnection = value;
    for (final connection in connections) {
      connection._activeConnection = this;
    }
  }

  List<RailConnection> connections = [];

  void addConnection(RailConnection other) {
    final targetAngle = (angle - pi) % (2 * pi);
    assert(other.angle == targetAngle);

    connections.add(other);
    activeConnection ??= other;
    other.activeConnection ??= this;
    // assert(
    //   connections.length <= 3,
    //   "There are only 3 directions; left, right, and neutral.",
    // );
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

  bool _locked = false;

  bool get locked => _locked || connections.any((c) => c._locked);

  set locked(bool value) {
    _locked = value;
    for (final connection in connections) {
      connection._locked = value;
      // Set locked recursively one time, so that forcing a switch will cause
      // neighbors to update
      for (final other in connection.connections) {
        other._locked = value;
      }
    }
  }

  void setActive(int steering) {
    if (locked) throw StateError("Cannot modified a locked switch");

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
    if (kDebugMode && debugConnections) {
      paint = Paint();
      if (locked) paint.color = Colors.red.withOpacity(.1);
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
    if (kDebugMode && debugDirections) {
      super.render(canvas);
    }
  }
}

typedef ConnectionMap = Map<CellCoord, List<RailConnection>>;

extension ConnectionOps on ConnectionMap {
  void addConnection(RailConnection connection) {
    final rail = connection.rail;
    final cCell = rail.coord + connection.coord;
    final cAngle = connection.angle;
    _register(cCell, connection);
    // Offset by 1.4 so that if we have diagonal rails in the future, they'll
    // round up, while cardinal rails will round down.
    final targetOffset =
        cCell.toOffset() + Offset.fromDirection(cAngle - pi, 1.4);
    final targetCell = targetOffset.toCoord();
    final partnerAngle = (connection.angle - pi) % (2 * pi);
    final partners = this[targetCell]?.where((p) {
      return p.angle == partnerAngle;
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
