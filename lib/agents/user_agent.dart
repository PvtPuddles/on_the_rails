import 'package:collection/collection.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/services.dart';
import 'package:on_the_rails/agents/agent.dart';
import 'package:on_the_rails/app.dart';
import 'package:on_the_rails/components/rails/rail.dart';
import 'package:on_the_rails/components/train/train.dart';
import 'package:on_the_rails/items/inventory.dart';
import 'package:on_the_rails/world/world.dart';

class UserAgent extends TrainAgent
    with KeyboardHandler, HasGameReference, Notifier {
  UserAgent._();

  static final instance = UserAgent._();

  @override
  OnTheRails get game => super.game as OnTheRails;

  PositionComponent? _focus;

  PositionComponent? get focus => _focus;

  set focus(PositionComponent? value) {
    if (_oldFocus is TrainCar) {
      _oldFocus!.position.removeListener(_showPois);
    }
    _oldFocus = _focus;
    _lerpStart = DateTime.now();
    _focus = value;
    if (_focus is TrainCar) {
      _focus!.position.addListener(_showPois);
    }
    _showPois();
    notifyListeners();
  }

  @override
  void update(double dt) {
    final train = activeTrain;
    if (train != null) {
      final targetThrottle =
          train.throttle + (TrainAgent.throttleSpeed * _throttleDirection) * dt;
      train.throttle = targetThrottle;

      if (focus != null) {
        game.camera.viewfinder.position = _lerpPosition((c) => c.position);
      }
    }

    super.update(dt);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    bool claimed = !handleTrainControls(event, keysPressed);
    if (claimed) return false;

    return true;
  }

  int _throttleDirection = 0;
  int steps = 0;

  bool handleTrainControls(
      KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final train = activeTrain;
    if (train == null) return false;

    if (event is KeyDownEvent) {
      switch (event.logicalKey) {
        /// Movement
        case LogicalKeyboardKey.keyW when train.throttle < 1:
          _throttleDirection = 1;
        case LogicalKeyboardKey.keyS when train.throttle > 0:
          _throttleDirection = -1;
        case LogicalKeyboardKey.keyA:
          train.steering = -1;
        case LogicalKeyboardKey.keyD:
          train.steering = 1;
        case LogicalKeyboardKey.shiftLeft when train.speed == 0:
          train.transmission *= -1;

        /// Other Stuff
        case LogicalKeyboardKey.space:
          train.append(TrainCar(
            name: "Boxcar",
            length: 35 * worldScale,
            width: gauge + 4,
            inventory: Inventory(width: 4, height: 5),
          ));
        case LogicalKeyboardKey.delete || LogicalKeyboardKey.backspace:
          final removed = train.cars.removeLast();
          game.world.remove(removed);

        default:
          return true;
      }
      return false;
    } else if (event is KeyUpEvent) {
      switch (event.logicalKey) {
        /// Movement
        case LogicalKeyboardKey.keyW || LogicalKeyboardKey.keyS:
          _throttleDirection = -1;
          _throttleDirection = 0;
        case LogicalKeyboardKey.keyA when train.steering == -1:
          train.steering = 0;
        case LogicalKeyboardKey.keyD when train.steering == 1:
          train.steering = 0;

        default:
          return true;
      }
      return false;
    }

    return false;
  }

  PositionComponent? _oldFocus;
  DateTime? _lerpStart;
  static const Duration _lerpDuration = Duration(milliseconds: 250);

  /// Lerps between the *current* [_oldFocus]'s position and the *current*
  /// [focus]'s position.
  Vector2 _lerpPosition(Vector2 Function(PositionComponent) positionOf) {
    if (focus == null) return Vector2.zero();
    final targetPos = positionOf(focus!);
    if (_lerpStart == null) return targetPos;
    final t = DateTime.now().difference(_lerpStart!).inMilliseconds /
        _lerpDuration.inMilliseconds;
    if (t >= 1) return targetPos;

    if (_oldFocus == null) return targetPos;
    final oldPos = positionOf(_oldFocus!);
    if (t <= 0) return oldPos;

    return Offset.lerp(
      oldPos.toOffset(),
      targetPos.toOffset(),
      t,
    )!
        .toVector2();
  }

  void _showPois() {
    final car = _focus as TrainCar;
    if ((car.train?.speed ?? 0) < 4) {
      final riderPois = [car.frontRider.rail, car.backRider.rail]
          .map((rail) =>
              rail == null ? null : game.world.poiMap.poisByRail[rail])
          .whereNotNull();
      game.poiManager.set(riderPois.flattened.toSet());
    } else {
      game.poiManager.dismiss();
    }
  }
}
