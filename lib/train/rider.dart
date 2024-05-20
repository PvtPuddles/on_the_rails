part of 'train.dart';

class Rider extends SpriteComponent with HasGameReference {
  Rider({
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

  int _railDirection = 1;
  double speed = 0;
  Rail? rail;
  double _distanceInRail = 0;

  double get _distance => _distanceInRail;

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

      if (steering != null && connection.connections.length > 1) {
        connection.setActive(steering!);
      }

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

  /// Place this rider [distance] units behind [other].
  void trail(Rider other, {required double distance}) {
    rail = other.rail;
    _railDirection = other._railDirection;
    _distance = other._distance;
    _distance -= distance * _railDirection;
  }
}
