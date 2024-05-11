// @Formatter:Off
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/services.dart';
import 'package:on_the_rails/rails/rail.dart';
// @Formatter:On

class Rider extends SpriteComponent with HasGameReference, KeyboardHandler {
  Rider({
    required this.rail,
    super.children,
    super.angle,
  }) : super(
          size: Vector2.all(cellSize),
          anchor: Anchor.center,
        ) {
    distanceInRail = 0;
  }

  @override
  void onLoad() {
    sprite = Sprite(game.images.fromCache("rails/debug/rider.png"));
  }

  double speed = 0;
  final Rail rail;
  double _distanceInRail = 0;

  double get distanceInRail => _distanceInRail;

  set distanceInRail(double distance) {
    _distanceInRail = distance;
    if (_distanceInRail >= rail.metric.length) {
      // TODO : Advance
      _distanceInRail -= rail.metric.length;
    } else if (_distanceInRail < 0) {
      // TODO : Retreat
    }
    final tangent = rail.tangentForOffset(distanceInRail);
    position = tangent.position.toVector2();
    angle = tangent.angle;
  }

  @override
  set position(Vector2 value) => super.position = value;

  @override
  set angle(double value) => super.angle = value + pi / 2;

  @override
  void update(double dt) {
    distanceInRail += speed;
    // final speedOffset = Offset.fromDirection(angle - pi / 2, speed);
    // position += Vector2(speedOffset.dx, speedOffset.dy);

    super.update(dt);
  }

  @override
  bool onKeyEvent(event, Set<LogicalKeyboardKey> keysPressed) {
    if (keysPressed.contains(LogicalKeyboardKey.keyW)) {
      speed += .05;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyS)) {
      speed -= .05;
    }

    return false;
  }
}
