// @Formatter:Off
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/services.dart';
import 'package:on_the_rails/rails/rail.dart';
import 'package:on_the_rails/world.dart';
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

  int _railDirection = 1;
  double speed = 0;
  Rail rail;
  double _distanceInRail = 0;

  double get distanceInRail => _distanceInRail;

  set distanceInRail(double distance) {
    _distanceInRail = distance;

    final len = rail.metric.length;

    bool outOfBounds = distance >= len || distance < 0;
    if (outOfBounds) {
      // The amount we've "overshot" this rail in either direction
      final excessProgress = distance < 0 ? distance.abs() : distance - len;
      final connection =
          _distanceInRail < 0 ? rail.startingConnection : rail.endingConnection;

      final newConnection = connection.activeConnection;
      if (newConnection == null) {
        _distanceInRail = excessProgress;
        // TODO : probably shouldn't...
        throw Exception("You crashed, so now I crash");
      } else {
        if (newConnection.atRailStart) {
          rail = newConnection.rail;
          _distanceInRail = excessProgress;
        } else {
          rail = newConnection.rail;
          _distanceInRail = rail.metric.length - excessProgress;
        }
        // Rails changed directions
        if (connection.atRailStart == newConnection.atRailStart) {
          _railDirection *= -1;
        }
      }
    }
    final tangent = rail.tangentForOffset(_distanceInRail);
    position = tangent.position.toVector2();
    if (_railDirection == 1) {
      angle = tangent.angle;
    } else {
      angle = (tangent.angle - pi) % (2 * pi);
    }
  }

  @override
  set position(Vector2 value) => super.position = value;

  @override
  set angle(double value) => super.angle = value;

  @override
  void update(double dt) {
    distanceInRail += speed * _railDirection;
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

    return true;
  }
}
