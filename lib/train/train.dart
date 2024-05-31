import 'dart:math';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:on_the_rails/agents/agent.dart';
import 'package:on_the_rails/agents/user_agent.dart';
import 'package:on_the_rails/app.dart';
import 'package:on_the_rails/items/inventory.dart';
import 'package:on_the_rails/items/item.dart';
import 'package:on_the_rails/priorities.dart';
import 'package:on_the_rails/rails/rail.dart';
import 'package:on_the_rails/rails/rail_connection.dart';
import 'package:on_the_rails/ui/widgets/inventory.dart';
import 'package:on_the_rails/ui/widgets/train/train_car_tooltip.dart';
import 'package:on_the_rails/world.dart';

part 'engine.dart';
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
    for (final car in cars) {
      car.train = this;
    }
  }

  TrainAgent? agent;

  List<TrainCar> cars;

  double get maxSpeed => cars.map((e) => e.maxSpeed).min;

  /// Total train weight, in tons.
  double get weight => cars.map((e) => e.weight).sum;

  double get power {
    final engines = cars.whereType<Engine>();
    if (engines.isEmpty) return 0;
    return engines.map((e) => e.power).sum;
  }

  double get brakingForce {
    final engines = cars.whereType<Engine>();
    if (engines.isEmpty) return 0;
    return engines.map((e) => e.brakingForce).sum;
  }

  late final double maxReverseSpeed = .5 * maxSpeed;
  double speed = 0;

  Rider get driver =>
      transmission.sign >= 0 ? cars.first.frontRider : cars.last.backRider;
  Rider get tail =>
      transmission.sign >= 0 ? cars.last.backRider : cars.first.frontRider;

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
    car.train = this;
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
      speed += min((power / (weight / 10)) * dt, targetSpeed - speed);
      if (oldSpeed == 0 && speed != 0) _onStart();
    } else if (targetSpeed < speed) {
      speed -= min((brakingForce / (weight / 10)) * dt, speed - targetSpeed);
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

  int _transmission = 1;

  int get transmission => _transmission;

  set transmission(int value) {
    if (value.sign == _transmission.sign) return;
    driver.steering = null;
    _transmission = value;
  }

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
    if (value == null || value == 0) {
      driver.steering = value;
    } else {
      driver.steering = value * transmission.sign;
    }
  }

  int? get steering {
    final value = driver.steering;
    if (value == null || value == 0) {
      return value;
    } else {
      return value * transmission.sign;
    }
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    return cars.any((car) => car.containsPoint(car.parentToLocal(point)));
  }

  /// Test whether the `point` (given in global coordinates) lies within this
  /// component. The top and the left borders of the component are inclusive,
  /// while the bottom and the right borders are exclusive.
  @override
  bool containsPoint(Vector2 point) {
    return cars.any((car) => car.containsPoint(point));
  }
}
