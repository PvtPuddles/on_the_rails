part of 'train.dart';

class Engine extends TrainCar with TrainCarTooltip {
  Engine({
    super.name,
    super.frontRider,
    super.backRider,
    required super.length,
    super.debugLabel,
    super.riderSpacing,
    required this.power,
    super.weight,
    double? brakingForce,
  }) : brakingForce = brakingForce ?? power * 3;

  Engine.single({
    super.name,
    super.frontRider,
    required super.length,
    super.debugLabel,
    required this.power,
    super.weight,
    double? brakingForce,
  })  : brakingForce = brakingForce ?? power * 3,
        super.single();

  /// Engine power, in arbitrary units.
  final double power;

  /// Braking force, in arbitrary units.
  final double brakingForce;

  @override
  Widget? buildContent(BuildContext context) {
    return Placeholder();
  }
}

/// Creates a Jupiter 4-4-0 steam engine.
Engine buildJupiter() => Engine(
      name: "Jupiter 4-4-0",
      length: 100,
      power: 10,
      weight: 32,
    );

Engine buildHandCart() => Engine.single(
      name: "Hand Car",
      length: 40,
      power: .1,
      weight: .5,
      brakingForce: 1,
    );
