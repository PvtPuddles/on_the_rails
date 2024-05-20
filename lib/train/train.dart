import 'dart:math';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:on_the_rails/agents/agent.dart';
import 'package:on_the_rails/priorities.dart';
import 'package:on_the_rails/rails/rail.dart';
import 'package:on_the_rails/world.dart';

part 'rider.dart';
part 'train_car.dart';

const double followDist = 10;

class Train extends Component with HasGameRef, KeyboardHandler {
  Train({
    super.key,
    required this.cars,
    this.agent,
  }) : assert(cars.isNotEmpty) {
    if (agent != null) {
      if (agent!.activeTrain != this) {
        agent?.activeTrain = this;
      }
    }
  }

  TrainAgent? agent;

  List<TrainCar> cars;

  final double acceleration = 1;
  late final double brakingSpeed = 3 * acceleration;

  final double maxSpeed = 30;
  late final double maxReverseSpeed = .5 * maxSpeed;
  double speed = 0;

  Rider get driver => speed >= 0 ? cars.first.frontRider : cars.last.backRider;

  set rail(Rail? value) {
    for (final car in cars) {
      car.rail = value;
    }
  }

  @override
  void onMount() {
    for (final car in cars) {
      game.world.add(car);
    }
    if (agent != null) {
      if (game.world.contains(agent!)) {
        game.world.add(agent!);
      }
    }
  }

  @override
  void onRemove() {
    for (final car in cars) {
      game.world.remove(car);
    }
  }

  void append(TrainCar car) {
    if (!car.isMounted) {
      game.world.add(car);
    }
    car.trail(cars.last, distance: followDist);
    cars.add(car);
  }

  @override
  void update(double dt) {
    final maxSpeed = transmission.sign > 0 ? this.maxSpeed : maxReverseSpeed;
    final targetSpeed = throttle * maxSpeed;

    final oldSpeed = speed;
    if (targetSpeed > speed) {
      speed += min(acceleration * dt, targetSpeed - speed);
      if (oldSpeed == 0 && speed != 0) _onStart();
    } else if (targetSpeed < speed) {
      speed -= min(brakingSpeed * dt, speed - targetSpeed);
      if (oldSpeed != 0 && speed == 0) _onStop();
    }

    if (speed != 0) {
      cars.first.frontRider.moveForward(speed * transmission.sign * dt * 10);
    }

    for (final (index, car) in cars.indexed) {
      if (index != 0) {
        car.trail(cars[index - 1], distance: followDist);
      }
    }
  }

  /// Called when the train starts moving
  void _onStart() {
    driver.steering = 0;
  }

  /// Called when the train stops moving
  void _onStop() {
    final oldDriver =
        throttle.sign >= 0 ? cars.first.frontRider : cars.last.backRider;
    oldDriver.steering = null;
  }

  int transmission = 1;

  double _throttle = 0;

  double get throttle => _throttle;

  set throttle(double value) {
    final target = clampDouble(value, 0, 1);
    if (_throttle != target) {
      _throttle = target;
    }
  }

  /// Sets the steering direction of the driving rider.
  set steering(int? value) {
    driver.steering = value;
  }

  int? get steering => driver.steering;
}
