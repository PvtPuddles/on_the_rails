import 'package:collection/collection.dart';
import 'package:flame/components.dart';
import 'package:flutter/cupertino.dart';

import 'bend.dart' as bend;
import 'straight.dart' as straight;

final Vector2 cellSize = Vector2.all(64);

const allRails = [
  ...bend.rails,
  ...straight.rails,
];

abstract class Rail extends SpriteComponent with HasGameReference {
  Rail({
    required this.name,
    required this.shape,
    required super.position,
  }) : super(
          size: sizeOf(shape),
          anchor: anchorFrom(shape),
        );

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
    final domain = (-bounds.$1.x) + bounds.$2.y + 1;

    const y = 1.0; // Bottom
    final x = (xValue - .5) / domain;
    return Anchor(x, y);
  }

  @visibleForTesting
  static (Vector2, Vector2) boundsOf(List<Vector2> shape) {
    assert(shape.any((cell) => cell.x == 0 && cell.y == 0));
    final minX = shape.map((e) => e.x).min;
    final maxX = shape.map((e) => e.x).max;
    final minY = shape.map((e) => e.x).min;
    final maxY = shape.map((e) => e.x).max;
    assert(minX <= 0 && maxX >= 0);
    return (Vector2(minX, maxX), Vector2(minY, maxY));
  }

  @visibleForTesting
  static Vector2 sizeOf(List<Vector2> shape) {
    final bounds = Rail.boundsOf(shape);
    final size = Vector2(
      (bounds.$1.y - bounds.$1.x) + 1,
      (bounds.$2.y - bounds.$2.x) + 1,
    );
    size.multiply(cellSize);
    return size;
  }
}
