part of 'train.dart';

class TrainCar extends RectangleComponent
    with
        HasGameRef,
        TapCallbacks,
        HoverCallbacks,
        TrainCarTooltip,
        HasInventory {
  TrainCar({
    super.key,
    this.name,
    required double length,
    double width = gauge,
    this.debugLabel,
    double? riderSpacing,
    this.maxSpeed = 30,
    this.weight = 22,
    this.inventory,
  })  : riderSpacing = riderSpacing ??
            max((length - (8 * worldScale)) * 3 / 4, (8 * worldScale)),
        super(
          priority: Priority.railCar,
          size: Vector2(length, width),
          position: Vector2.zero(),
          paint: Paint()..color = Colors.greenAccent,
          anchor: Anchor.center,
        ) {
    frontRider = Rider(car: this);
    _backRider = Rider(car: this);
  }

  TrainCar.single({
    super.key,
    this.name,
    required double length,
    double width = gauge,
    this.debugLabel,
    this.maxSpeed = 30,
    this.weight = 22,
    this.inventory,
  })  : _backRider = null,
        riderSpacing = 0,
        super(priority: Priority.railCar) {
    frontRider = Rider(car: this);
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

  Train? train;

  bool get isDriver {
    if (train == null) return true;
    switch (train!.transmission) {
      case >= 0:
        return train!.cars.first == this;
      default:
        return train!.cars.last == this;
    }
  }

  bool get isCaboose {
    if (train == null) return true;
    switch (train!.transmission) {
      case >= 0:
        return train!.cars.last == this;
      default:
        return train!.cars.first == this;
    }
  }

  bool get isStopped => train?.isStopped ?? true;

  final Inventory? inventory;

  @override
  late final Iterable<Inventory> inventories = [inventory].whereNotNull();

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

  late final Rider frontRider;
  late final Rider? _backRider;

  Rider get backRider => _backRider ?? frontRider;

  void _updatePosition() {
    _backRider?.trail(frontRider, distance: riderSpacing);

    if (_backRider == null) {
      if (position != frontRider.position) position = frontRider.position;
      if (angle != frontRider.angle) angle = frontRider.angle;
    } else {
      final newPos = (frontRider.position + _backRider.position) / 2;
      if (position != newPos) position = newPos;
      final direction =
          (frontRider.position - position).toOffset().direction % (2 * pi);
      if (angle != direction) angle = direction;
    }
  }

  set rail(Rail? value) {
    frontRider.rail = value;
    if (value != null) {
      frontRider._distance = value.metric.length - min(20, value.metric.length);
    } else {
      frontRider._distance = 0;
    }
    _updatePosition();
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

  @override
  String toString() {
    final designator = train == null
        ? ""
        : isDriver
            ? "👑"
            : isCaboose
                ? "💨"
                : "🔗";
    return "$designator${name ?? debugLabel}";
  }
}
