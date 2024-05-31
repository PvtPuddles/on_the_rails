part of 'train.dart';

class Engine extends TrainCar with TrainCarTooltip {
  Engine({
    super.name,
    required super.length,
    super.debugLabel,
    super.riderSpacing,
    required this.power,
    super.weight,
    double? brakingForce,
    super.inventory,
    this.fuelTank,
  }) : brakingForce = brakingForce ?? power * 3;

  Engine.single({
    super.name,
    required super.length,
    super.debugLabel,
    required this.power,
    super.weight,
    double? brakingForce,
    super.inventory,
    this.fuelTank,
  })  : brakingForce = brakingForce ?? power * 3,
        super.single();

  /// A secondary inventory from which the engine pulls fuel from.
  final FuelTank? fuelTank;

  /// Engine power, in arbitrary units.
  final double power;

  /// Braking force, in arbitrary units.
  final double brakingForce;

  // TODO : Speed indicator, break, and transmission
  @override
  Widget? buildContent(BuildContext context) {
    return Row(
      children: [
        if (fuelTank != null)
          InventoryWidget(
            fuelTank!,
            game: game as OnTheRails,
          ),
      ],
    );
  }
}

/// Creates a Jupiter 4-4-0 steam engine.
List<TrainCar> buildJupiter() {
  final engine = Engine(
    name: "Jupiter 4-4-0",
    length: 100,
    power: 10,
    weight: 32,
    fuelTank: FuelTank(width: 2, height: 2),
  );
  final fuelCar = TrainCar(
    length: 70,
    name: "Fuel Car",
    weight: 10,
    inventory: FuelTank(width: 2, height: 4),
  );
  for (int i = 0; i < fuelCar.inventory!.cellCount; i++) {
    fuelCar.inventory!.insert(
      // We want 8 different coal objects, plz and thx :P
      // ignore: prefer_const_constructors
      Fuel(name: 'Coal', itemType: ItemType.bulk),
    );
  }
  return [
    engine,
    fuelCar,
  ];
}

Engine buildHandCart() => Engine.single(
      name: "Hand Car",
      length: 40,
      power: .1,
      weight: .5,
      brakingForce: 1,
    );
