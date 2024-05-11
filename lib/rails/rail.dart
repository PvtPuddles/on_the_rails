import 'dart:math';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:on_the_rails/app.dart' show cellSize;
import 'package:on_the_rails/components/path_component.dart';

import 'bend.dart' as bend;
import 'straight.dart' as straight;

export 'package:flutter/material.dart';
export 'package:on_the_rails/app.dart' show cellSize;

const drawCells = true;
const drawPaths = true;

const allRails = [
  ...bend.rails,
  ...straight.rails,
];

abstract class Rail extends SpriteComponent with HasGameReference {
  Rail({
    required this.name,
    required this.shape,
    required super.position,
    super.children,
    super.angle,
  }) : super(
          size: sizeOf(shape),
          anchor: anchorFrom(shape),
        ) {
    if (kDebugMode) addAll(_debugComponents(shape));
  }

  final String name;

  /// The cells that this rail covers, relative to the anchor cell (0, 0)
  ///
  /// These will be considered "occupied" cells.
  final List<Vector2> shape;

  @override
  void onLoad() {
    sprite = Sprite(game.images.fromCache("rails/$name.png"));
  }

  static Anchor anchorFrom(List<Vector2> shape) {
    final bounds = Rail.boundsOf(shape);
    // Relative position of x=0 from bounds.start
    final xValue = -bounds.$1.x + 1;
    final domain = (-bounds.$1.x) + bounds.$1.y + 1;
    // Relative position of y=0 from bounds.start
    final yValue = -bounds.$2.x + 1;
    final range = (-bounds.$2.x) + bounds.$2.y + 1;

    final x = (xValue - .5) / domain;
    final y = (yValue - .5) / range; // Center

    final anchorPos = Vector2(x, y);
    return Anchor(anchorPos.x, anchorPos.y);
  }

  @visibleForTesting
  static (Vector2, Vector2) boundsOf(List<Vector2> shape) {
    assert(shape.any((cell) => cell.x == 0 && cell.y == 0));
    final minX = shape.map((e) => e.x).min;
    final maxX = shape.map((e) => e.x).max;
    final minY = shape.map((e) => e.y).min;
    final maxY = shape.map((e) => e.y).max;
    assert(minX <= 0 && maxX >= 0);
    assert(minY <= 0 && maxY >= 0);
    return (Vector2(minX, maxX), Vector2(minY, maxY));
  }

  @visibleForTesting
  static Vector2 sizeOf(List<Vector2> shape) {
    final bounds = Rail.boundsOf(shape);
    final size = Vector2(
      (bounds.$1.y - bounds.$1.x) + 1,
      (bounds.$2.y - bounds.$2.x) + 1,
    );
    size.multiply(Vector2.all(cellSize));
    return size;
  }

  /// Local-space path describing this rail
  late final Path path = buildPath();
  late final PathMetric metric = path.computeMetrics().first;

  Tangent tangentForOffset(double distance) {
    assert(distance >= 0 && distance < metric.length);
    final tangent = metric.getTangentForOffset(distance)!;

    final origin = metric.getTangentForOffset(0)!;

    final anchorOffset = Offset.fromDirection(angle - pi / 2, cellSize / 2);
    final localPosition = tangent.position - origin.position;
    final rotatedPos = localPosition.toVector2()..rotate(angle);
    return Tangent((rotatedPos + position).toOffset() - anchorOffset,
        Offset.fromDirection(tangent.angle - angle));
  }

  @protected
  Path buildPath();

  List<PositionComponent> _debugComponents(List<Vector2> shape) {
    return [
      if (drawPaths) PathComponent(path, position: Vector2(0, 0)),
    ];
  }
}

class RailCell extends SpriteComponent with HasGameReference {
  RailCell({
    required super.position,
  })  : name = "rail_cell",
        super(
          size: Vector2.all(cellSize),
          anchor: Anchor.center,
        );

  RailCell.occupied({
    required super.position,
  })  : name = "rail_cell_occupied",
        super(
          size: Vector2.all(cellSize),
          anchor: Anchor.center,
        );

  RailCell.origin({
    required super.position,
    required super.angle,
  })  : name = "rail_segment_start",
        super(
          size: Vector2.all(cellSize),
          anchor: Anchor.center,
        );

  String name;

  @override
  void onLoad() {
    sprite = Sprite(game.images.fromCache("rails/debug/$name.png"));
  }
}
