import 'dart:math';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flame/components.dart';
import 'package:on_the_rails/components/buildings/poi.dart';
import 'package:on_the_rails/components/rails/rail.dart';
import 'package:on_the_rails/items/inventory.dart';
import 'package:on_the_rails/world/world.dart';

class Platform extends RectangleComponent with HasGameRef, HasInventory, Poi {
  Platform({
    this.name = "Platform",
    required this.coord,
    required this.length,
    this.inventory,
    super.angle,
  })  : assert((angle ?? 0) % (pi / 2) == 0),
        super(
          priority: 5,
          anchor: Anchor(1 / (2 * length), .5),
          paint: Paint()..color = const Color(0xFF738A76),
          position: coord.toVector() * cellSize +
              (Vector2(0, sleeperWidth)..rotate(angle ?? 0)),
          size: Vector2(
            cellSize * length,
            sleeperWidth,
          ),
        ) {
    shape = CellShape([
      for (int i = 0; i < length; i++)
        (Vector2(i.toDouble(), 0)..rotate(angle)).toCoord()
    ]);
  }

  @override
  final String name;
  final CellCoord coord;
  final int length;
  final Inventory? inventory;

  @override
  Iterable<Inventory> get inventories => [inventory].whereNotNull();

  late final CellShape shape;

  late final Vector2 _dirToRail = Vector2(0, 1)..rotate(angle);

  @override
  List<Rail> get rails {
    Set<Rail> rails = {};
    for (final cell in shape.cells) {
      var pos = coord + cell;
      pos += CellCoord(_dirToRail.x.toInt(), _dirToRail.y.toInt());

      final cellRails = railMap[pos];
      rails.addAll(cellRails);
    }
    return rails.toList();
  }

  @override
  void onMount() {
    for (final rail in rails) {
      rail.debugPathColor = paint.color;
    }
    super.onMount();
  }
}
