part of 'train.dart';

class Rider extends SpriteComponent with HasGameReference {
  Rider({
    required this.car,
    this.rail,
    super.children,
    super.angle,
  }) : super(
          priority: Priority.rider,
          size: Vector2.all(cellSize),
          anchor: Anchor.center,
        ) {
    _distanceInRail = 0;
  }

  @override
  void onLoad() {
    sprite = Sprite(game.images.fromCache("rails/debug/rider.png"));
  }

  final TrainCar car;

  int _railDirection = 1;
  double speed = 0;
  Rail? rail;
  double _distanceInRail = 0;

  double get _distance => _distanceInRail;

  /// Whether this rider is the head of the train.
  bool get isDriver => this == car.train?.driver;

  /// Whether this rider is the tail of the train.
  bool get isTail => this == car.train?.tail;

  int? steering;

  set _distance(double distance) {
    if (rail == null) {
      throw StateError("Rider cannot advance along null rail");
    }
    _distanceInRail = distance;

    while (_distanceInRail >= rail!.metric.length || _distanceInRail < 0) {
      final len = rail!.metric.length;

      // The amount we've "overshot" this rail in either direction
      final excessProgress =
          _distanceInRail < 0 ? -_distanceInRail : _distanceInRail - len;
      final connection = _distanceInRail < 0
          ? rail!.startingConnection
          : rail!.endingConnection;

      onConnectionTraversed(connection);

      final newConnection = connection.activeConnection;
      if (newConnection == null) {
        _distanceInRail = excessProgress;
        // TODO : probably shouldn't...
        throw Exception("You crashed, so now I crash");
      } else {
        newConnection.activeConnection = connection;

        if (newConnection.atRailStart) {
          rail = newConnection.rail;
          _distanceInRail = excessProgress;
        } else {
          rail = newConnection.rail;
          _distanceInRail = rail!.metric.length - excessProgress;
        }
        // Rails changed directions
        if (connection.atRailStart == newConnection.atRailStart) {
          _railDirection *= -1;
        }
      }
    }

    final tangent = rail!.tangentForOffset(_distanceInRail);
    position = tangent.position.toVector2();
    if (_railDirection == 1) {
      angle = tangent.angle;
    } else {
      angle = (tangent.angle - pi) % (2 * pi);
    }
  }

  void onConnectionTraversed(RailConnection connection) {
    if (isTail) {
      // if (connection.locked && connection.connections.length > 1) {
      //   // This should be logged sometime in the future
      //   print("Unlocked by $this");
      // }
      connection.locked = false;
    } else {
      // if (!connection.locked && connection.connections.length > 1) {
      //   // This should be logged sometime in the future
      //   print("Locked by $this");
      // }
      if (isDriver && !connection.locked) {
        if (steering != null && connection.connections.length > 1) {
          connection.setActive(steering!);
        }
      }
      connection.locked = true;
    }
  }

  void moveForward(double distance) {
    if (distance != 0) {
      _distance += distance * _railDirection;
    }
  }

  @override
  set position(Vector2 value) => super.position = value;

  @override
  set angle(double value) => super.angle = value;

  @override
  void update(double dt) {
    if (speed != 0) {
      moveForward(speed * dt);
    }
  }

  /// Number of pixels a rail car is allowed to trail another by
  static const double _epsilon = .1;

  /// Place this rider [distance] units behind [other], with a tolerance of [epsilon].
  void trail(Rider other, {required double distance}) {
    if (rail == null) {
      _resetBehind(other, distance: distance);
    } else if ((other.position - position).length > 2 * distance) {
      _resetBehind(other, distance: distance);
    }

    final actualDist = (other.position - position).length;
    final delta = actualDist - distance;
    if (delta.abs() > _epsilon) moveForward(delta);
  }

  /// Hard-reset a rider to a certain distance behind [other].
  ///
  /// Be cautious, as this may leave some switches incorrectly locked/unlocked.
  void _resetBehind(Rider other, {required double distance}) {
    rail = other.rail;
    _railDirection = other._railDirection;
    _distance = other._distance;
    _distance -= distance * _railDirection;
  }

  @override
  String toString() {
    final designator = car.frontRider == this ? "Font" : "Back";
    return "${designator}Rider($car)";
  }
}
