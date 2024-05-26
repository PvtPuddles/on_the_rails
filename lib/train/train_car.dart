part of 'train.dart';

class TrainCar extends RectangleComponent
    with HasGameRef, TapCallbacks, HoverCallbacks {
  static const defaultWidth = cellSize / 4;

  TrainCar({
    super.key,
    this.name,
    Rider? frontRider,
    Rider? backRider,
    required double length,
    double width = gauge,
    this.debugLabel,
    double? riderSpacing,
    this.maxSpeed = 30,
    this.weight = 22,
  })  : frontRider = frontRider ?? Rider(),
        _backRider = backRider ?? Rider(),
        riderSpacing = riderSpacing ?? max((length - 40) * 3 / 4, 30),
        super(priority: Priority.railCar) {
    size = Vector2(length, width);
    paint = Paint()..color = Colors.greenAccent;
    anchor = Anchor.center;
  }

  TrainCar.single({
    super.key,
    this.name,
    Rider? frontRider,
    required double length,
    double width = gauge,
    this.debugLabel,
    this.maxSpeed = 30,
    this.weight = 22,
  })  : frontRider = frontRider ?? Rider(),
        _backRider = null,
        riderSpacing = 0,
        super(priority: Priority.railCar) {
    size = Vector2(length, width);
    paint = Paint()..color = Colors.greenAccent;
    anchor = Anchor.center;
  }

  @override
  final String? name;

  final double maxSpeed;

  /// Train car weight, in tons.
  final double weight;

  double get length => size.x;
  double get carWidth => size.y;

  /// The number of units separating the front and back riders.
  double riderSpacing;

  String? debugLabel;

  @override
  void onMount() {
    frontRider.position.addListener(_updatePosition);
    final riders = [frontRider, backRider].whereNotNull();
    for (final rider in riders) {
      if (!game.world.contains(rider)) {
        game.world.add(rider);
      }
    }
    super.onMount();
  }

  @override
  void onRemove() {
    frontRider.position.removeListener(_updatePosition);
    game.world.remove(frontRider);
    if (_backRider != null) game.world.remove(_backRider);
    super.onRemove();
  }

  final Rider frontRider;
  final Rider? _backRider;

  Rider get backRider => _backRider ?? frontRider;

  void _updatePosition() {
    _backRider?.trail(frontRider, distance: riderSpacing);

    if (_backRider == null) {
      position = frontRider.position;
      angle = frontRider.angle;
    } else {
      position = (frontRider.position + _backRider.position) / 2;
      final direction = (frontRider.position - position).toOffset().direction;
      angle = direction % (2 * pi);
    }
  }

  double speed = 0;

  @override
  void update(double dt) {
    if (speed != 0) {
      frontRider.moveForward(speed * dt * 10);
    }

    super.update(dt);
  }

  set rail(Rail? value) {
    frontRider.rail = value;
    frontRider._distance = 0;
    _updatePosition();
    if (value == null) {
      speed = 0;
    }
  }

  void trail(TrainCar other, {required double distance}) {
    assert(other != this);
    distance +=
        (other.length - other.riderSpacing) / 2 + (length - riderSpacing) / 2;
    frontRider.trail(other.backRider, distance: distance);
    _updatePosition();
  }

  @override
  void onTapDown(TapDownEvent event) {
    final uAgent = UserAgent.instance;
    final ttm = TooltipManager.instance;

    if (uAgent.focus == this) {
      if (ttm.target == this && ttm.mode == TooltipMode.persistent) {
        ttm.showTooltip(this, mode: TooltipMode.fleeting);
      } else {
        ttm.showTooltip(this, mode: TooltipMode.persistent);
      }
      return;
    } else {
      ttm.target = null;
      uAgent.focus = this;
    }
  }

  @override
  void onHoverEnter() {
    final ttm = TooltipManager.instance;
    if (ttm.mode != TooltipMode.persistent) {
      ttm.showTooltip(this);
    }
  }

  @override
  void onHoverExit() {
    final ttm = TooltipManager.instance;
    if (ttm.mode != TooltipMode.persistent) {
      ttm.hideTooltip(this);
    }
  }
}
