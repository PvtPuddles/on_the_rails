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

  @override
  Iterable<Inventory> get inventories => [fuelTank, inventory].whereNotNull();

  /// Engine power, in arbitrary units.
  final double power;

  /// Braking force, in arbitrary units.
  final double brakingForce;

  // TODO : Speed indicator, break, and transmission
  @override
  Widget? buildContent(BuildContext context) {
    return const Row(
      children: [],
    );
  }
}

/// Creates a Jupiter 4-4-0 steam engine.
List<TrainCar> buildJupiter() {
  final engine = Engine(
    name: "Jupiter 4-4-0",
    length: cellSize * .8,
    power: 10,
    weight: 32,
    fuelTank: FuelTank(name: "Firebox", width: 2, height: 2),
  );
  final fuelCar = TrainCar(
    length: cellSize / 2,
    name: "Fuel Car",
    weight: 10,
    inventory: FuelTank(name: null, width: 2, height: 4),
  );
  for (int i = 0; i < 2; i++) {
    fuelCar.inventory!.insert(
      // We want multiple different objects, plz and thx :P
      // ignore: prefer_const_constructors
      Fuel(
        name: 'Coal',
        itemType: ItemType.packaged,
        modifiers: [ItemModifier.fireboxFuel, ItemModifier.moistureSensitive],
      ),
    );
  }
  for (int i = 0; i < 2; i++) {
    fuelCar.inventory!.insert(
      // We want multiple different objects, plz and thx :P
      // ignore: prefer_const_constructors
      Fuel(
        name: 'Firewood',
        itemType: ItemType.packaged,
        modifiers: [ItemModifier.fireboxFuel, ItemModifier.moistureSensitive],
        // shape: CellShape.unit,
        shape: const CellShape([CellCoord.zero, CellCoord(1, 0)]),
      ),
    );
  }
  return [
    engine,
    fuelCar,
  ];
}

Engine buildHandCart() => Engine.single(
      name: "Hand Car",
      length: cellSize / 2,
      power: .1,
      weight: .5,
      brakingForce: 1,
    );
