// https://en.wikipedia.org/wiki/Railroad_car#Types_of_freight_cars

import 'package:on_the_rails/coord.dart';

enum ItemType {
  /// Goods in boxes
  ///
  /// For use in box cars
  packaged,

  /// Coal, iron, etc
  ///
  /// For use in gondolas
  bulk,

  /// Big bulkies.
  ///
  /// For use on flatbeds
  industrial,

  /// Sloshy bois
  ///
  /// For use in tanks
  liquid,
}

enum ItemModifier {
  /// Modifier indicating that the good must be kept in food-safe containers.
  ///
  /// Food-safe containers may not carry anything that is not a food.
  food,

  /// Items that cannot be stored in the open air.
  moistureSensitive,

  /// Items that must be kept fresh in climate controlled cars.
  ///
  /// Can be used to describe goods that must be kept hot or cold.  Future idea:
  /// shelf life, which can be extended via insulation/climate control.
  temperatureSensitive,
}

class Item {
  const Item({
    required this.name,
    required this.itemType,
    this.modifiers = const [],
    this.shape = const [CellCoord.zero],
  });

  final String name;
  final ItemType itemType;
  final List<ItemModifier> modifiers;
  final List<CellCoord> shape;

  @override
  String toString() {
    return "Item($name)";
  }
}

class Fuel extends Item {
  const Fuel({
    required super.name,
    required super.itemType,
    super.modifiers,
    super.shape,
  });

  @override
  String toString() {
    return "Fuel($name)";
  }
}
