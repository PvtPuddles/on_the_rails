import 'package:flutter/material.dart';
import 'package:on_the_rails/coord.dart';
import 'package:on_the_rails/items/item.dart';

class Inventory extends ChangeNotifier {
  Inventory({
    required this.width,
    required this.height,
  }) : _data = List.filled(width * height, null);

  final int width;
  final int height;

  final List<Item?> _data;

  int get cellCount => width * height;

  Item? at(CellCoord coord) {
    assert(_contains(coord));
    return _data[_indexOf(coord)];
  }

  Item? atIndex(int index) {
    return _data[index];
  }

  bool contains(Item item) => _data.contains(item);

  bool canAdd(Item item, [CellCoord? origin]) {
    if (origin == null) {
      for (int i = 0; i < cellCount; i++) {
        if (_data[i] != null) continue;
        final coord = _coordOf(i);
        if (canAdd(item, coord)) return true;
      }
      return false;
    } else {
      // Turns out, moving items is a perfectly valid action...
      // if (_data.any((i) => item == i)) return false;

      for (final cell in item.shape) {
        final coord = cell + origin;

        if (!_contains(coord)) return false;

        if (_data[_indexOf(coord)] != null) return false;
      }
      return true;
    }
  }

  void insert(Item item, [CellCoord? origin]) {
    for (int i = 0; i < cellCount; i++) {
      final occupant = _data[i];
      if (occupant == item) {
        throw ArgumentError.value(
          item,
          "item",
          "Item is already in inventory.  Please remove the item before "
              "re-inserting.",
        );
      }
    }

    if (origin == null) {
      if (!canAdd(item)) {
        throw ArgumentError.value(item, "item", "No space for item");
      }

      for (int i = 0; i < cellCount; i++) {
        final coord = _coordOf(i);
        if (canAdd(item, coord)) {
          origin = coord;
          break;
        }
      }
    }
    origin!;
    // Assert item can be added
    for (final cell in item.shape) {
      final coord = cell + origin;
      if (!_contains(coord)) {
        throw RangeError(
          "Item out of bounds.  0 <= ${coord.x} < $width, 0 <= ${coord.y} < $height",
        );
      }

      final occupant = _data[_indexOf(coord)];
      if (occupant != null) {
        throw ArgumentError.value(
          item,
          "item",
          "Collision with other item: $occupant",
        );
      }
    }

    // Add a reference to the item to each cell
    for (final cell in item.shape) {
      final coord = cell + origin;
      _data[_indexOf(coord)] = item;
    }
    notifyListeners();
  }

  void remove(Item item) {
    final cells = _data.indexed.where((cell) => cell.$2 == item);

    // Remove the reference to the item in each cell
    for (final (index, _) in cells) {
      _data[index] = null;
    }
    notifyListeners();
  }

  /// Whether a given cell is within this' bounds.
  bool _contains(CellCoord coord) {
    if (coord.x < 0 || coord.x >= width) return false;
    if (coord.y < 0 || coord.y >= height) return false;
    return true;
  }

  int _indexOf(CellCoord coord) {
    assert(coord.x >= 0 && coord.x < width);
    assert(coord.y >= 0 && coord.y < height);
    return coord.y * width + coord.x;
  }

  CellCoord _coordOf(int index) {
    final row = index ~/ width;
    final column = index % width;
    return CellCoord(column, row);
  }
}

class FuelTank extends Inventory {
  FuelTank({
    required super.width,
    required super.height,
  });

  @override
  Fuel? at(CellCoord coord) {
    assert(_contains(coord));
    return _data[_indexOf(coord)] as Fuel?;
  }

  @override
  bool canAdd(Item item, [CellCoord? origin]) {
    if (item is! Fuel) return false;
    return super.canAdd(item, origin);
  }

  @override
  void insert(Item item, [CellCoord? origin]) {
    if (item is! Fuel) {
      throw ArgumentError.value(item, "item", "Item is not a fuel");
    }
    super.insert(item, origin);
  }

  @override
  void remove(Item item) {
    if (item is! Fuel) {
      throw ArgumentError.value(item, "item", "Item is not a fuel");
    }
    super.remove(item);
  }
}
