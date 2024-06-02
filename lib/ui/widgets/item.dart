// @formatter:off
import 'package:flutter/material.dart';
import 'package:on_the_rails/coord.dart';
import 'package:on_the_rails/items/item.dart';
import 'package:on_the_rails/ui/widgets/inventory.dart';
// @formatter:on

class ItemWidget extends StatelessWidget {
  static const cellSize = InventoryWidget.cellSize;

  const ItemWidget(this.item, {super.key});

  final Item? item;

  @override
  Widget build(BuildContext context) {
    final shape = item?.shape ?? CellShape.unit;
    final size = shape.size;

    return Card(
      shape: const CircleBorder(eccentricity: 1),
      color: Color.alphaBlend(Colors.pink.withOpacity(.25), Colors.white),
      child: SizedBox(
        width: size.x * cellSize,
        height: size.y * cellSize,
        child: Center(
            child: Text(
          item?.name ?? "",
          style: Theme.of(context)
              .textTheme
              .bodyMedium!
              .copyWith(color: Colors.black),
        )),
      ),
    );
  }
}
