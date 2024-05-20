import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:on_the_rails/agents/agent.dart';
import 'package:on_the_rails/train/train.dart';

class UserAgent extends TrainAgent with KeyboardHandler {
  UserAgent();

  @override
  void update(double dt) {
    final train = activeTrain;
    if (train != null) {
      final targetThrottle =
          train.throttle + (TrainAgent.throttleSpeed * _throttleDirection) * dt;
      train.throttle = targetThrottle;
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
          train.append(TrainCar(length: 100, riderSpacing: 50));
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
}
