import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:on_the_rails/coord.dart';
import 'package:on_the_rails/items/inventory.dart';
import 'package:on_the_rails/items/item.dart';
import 'package:on_the_rails/train/train.dart';
import 'package:on_the_rails/ui/widgets/item.dart';

class InventoryWidget extends StatefulWidget {
  static const double cellSize = 40;

  const InventoryWidget(
    this.inventory, {
    super.key,
    required this.game,
  });

  final Inventory inventory;
  final FlameGame game;

  @override
  State<InventoryWidget> createState() => _InventoryWidgetState();
}

class _InventoryWidgetState extends State<InventoryWidget> {
  Inventory get inventory => widget.inventory;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: inventory,
        builder: (context, _) {
          return Table(
            defaultColumnWidth:
                const FixedColumnWidth(InventoryWidget.cellSize),
            border: TableBorder.all(
              color: Theme.of(context).colorScheme.onBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            children: [
              for (int y = 0; y < inventory.height; y++)
                TableRow(
                  children: [
                    for (int x = 0; x < inventory.width; x++)
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: _tile(context, CellCoord(x, y)),
                        ),
                      )
                  ],
                )
            ],
          );
        });
  }

  Widget _tile(BuildContext context, CellCoord index) {
    final item = inventory.at(index);

    return DragTarget<Item>(
      onWillAcceptWithDetails: (details) {
        if (details.data == item) return true;
        if (item != null) return false;
        return inventory.canAdd(details.data, index);
      },
      onAcceptWithDetails: (details) {
        if (details.data == item) return;
        inventory.remove(details.data);
        inventory.insert(details.data, index);
      },
      builder: (BuildContext context, List<Object?> candidateData,
          List<dynamic> rejectedData) {
        if (item == null) {
          if (candidateData.isNotEmpty) {
            return _buildCandidate(context, item);
          }

          return const SizedBox();
        }

        return _buildDraggableItem(
          context,
          item,
          index,
        );
      },
    );
  }

  Widget _buildDraggableItem(BuildContext context, Item item, CellCoord index) {
    final itemWidget = ItemWidget(item);
    return Draggable<Item>(
      data: item,
      dragAnchorStrategy: (draggable, context, offset) {
        return const Offset(ItemWidget.cellSize / 2, ItemWidget.cellSize / 2);
      },
      onDragEnd: (details) {
        if (inventory.at(index) != item) {
          // Already found a home in a different DragTarget
          return;
        }
        final origin = details.offset.toVector2();
        final center = origin + Vector2.all(ItemWidget.cellSize / 2);
        // Fuck if I know why we need to make a copy of the list, but if I don't
        // this breaks on the 4th item, every time.
        final targetComponents =
            List.from(widget.game.componentsAtPoint(center));
        final car = targetComponents.whereType<TrainCar>().firstOrNull;

        if (car is Engine && (car.fuelTank?.canAdd(item) ?? false)) {
          inventory.remove(item);
          car.fuelTank!.insert(item);
        } else if (car?.inventory?.canAdd(item) ?? false) {
          inventory.remove(item);
          car!.inventory!.insert(item);
        }
      },
      feedback: itemWidget,
      childWhenDragging: _buildCandidate(context, item),
      child: itemWidget,
    );
  }

  Widget _buildCandidate(BuildContext context, Item? item) {
    return ColorFiltered(
      colorFilter:
          ColorFilter.mode(Colors.white.withOpacity(.25), BlendMode.srcIn),
      child: ItemWidget(item),
    );
  }
}
