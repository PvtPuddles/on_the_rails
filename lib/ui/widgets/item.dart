// @formatter:off
import 'package:flutter/material.dart';
import 'package:on_the_rails/items/item.dart';
import 'package:on_the_rails/ui/widgets/inventory.dart';
// @formatter:on

class ItemWidget extends StatelessWidget {
  static const cellSize = InventoryWidget.cellSize;

  const ItemWidget(this.item, {super.key});

  final Item? item;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: const CircleBorder(eccentricity: 1),
      child: SizedBox.square(
          dimension: cellSize,
          child: Center(
              child: Text(
            item?.name ?? "",
            style: Theme.of(context)
                .textTheme
                .bodyMedium!
                .copyWith(color: Colors.black),
          ))),
    );
  }
}
