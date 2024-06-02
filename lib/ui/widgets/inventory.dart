import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:on_the_rails/items/inventory.dart';
import 'package:on_the_rails/items/item.dart';
import 'package:on_the_rails/ui/widgets/item.dart';
import 'package:on_the_rails/world/world.dart';

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

  /// The position of the currently dragged item's origin in local space.
  ///
  /// Used to determine which cell the origin is over for inventory-space
  /// insertions.
  CellCoord? _itemCell;

  /// The local position of the cursor within the draggable.
  ///
  /// Used to determine where the cursor is for game-space insertions.
  Offset? _localPosition;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: inventory,
        builder: (context, _) {
          return DragTarget<ItemRef>(
            onWillAcceptWithDetails: (details) {
              _itemCell = _cellOf(details);
              return true;
            },
            onMove: (details) {
              final cell = _cellOf(details);
              if (cell != _itemCell) {
                setState(() {
                  _itemCell = cell;
                });
              }
            },
            onLeave: (_) {
              _itemCell = null;
            },
            onAcceptWithDetails: (details) {
              _itemCell = null;
              final cell = _cellOf(details);
              final ref = details.data;
              final item = ref.item;
              if (inventory.canAdd(item, cell)) {
                ref.inventory.remove(item);
                inventory.insert(item, cell);
              }
            },
            builder: (context, candidateData, rejectedData) {
              assert(candidateData.length <= 1);

              final ref = candidateData.firstOrNull;

              return Stack(
                children: [
                  Table(
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
                                verticalAlignment:
                                    TableCellVerticalAlignment.middle,
                                child: _tile(context, CellCoord(x, y)),
                                // child: AspectRatio(
                                //   aspectRatio: 1,
                                //   child: _tile(context, CellCoord(x, y)),
                                // ),
                              )
                          ],
                        )
                    ],
                  ),
                  for (final ref in inventory.items)
                    Positioned(
                      left: ref.origin.x * ItemWidget.cellSize,
                      top: ref.origin.y * ItemWidget.cellSize,
                      child: _buildDraggableItem(context, ref),
                    ),
                  if (_itemCell != null)
                    Positioned(
                      left: _itemCell!.x * InventoryWidget.cellSize,
                      top: _itemCell!.y * InventoryWidget.cellSize,
                      child: _buildCandidate(context, ref?.item, _itemCell),
                    )
                ],
              );
            },
          );
        });
  }

  CellCoord _cellOf(DragTargetDetails<ItemRef> details) {
    final RenderBox renderObject = context.findRenderObject()! as RenderBox;
    final localPos = renderObject.globalToLocal(details.offset);
    final item = details.data.item;
    final originPos =
        localPos + (item.shape.origin * ItemWidget.cellSize).toOffset();
    return CellCoord(originPos.dx ~/ ItemWidget.cellSize,
        originPos.dy ~/ ItemWidget.cellSize);
  }

  Widget _tile(BuildContext context, CellCoord index) {
    return const SizedBox.square(dimension: InventoryWidget.cellSize);
  }

  Widget _buildDraggableItem(BuildContext context, ItemRef ref) {
    final item = ref.item;
    final index = ref.origin;
    final itemWidget = ItemWidget(item);
    final size = item.shape.size * ItemWidget.cellSize;
    return SizedBox(
      width: size.x,
      height: size.y,
      child: Draggable<ItemRef>(
        data: ref,
        dragAnchorStrategy: (draggable, context, position) {
          final RenderBox renderObject =
              context.findRenderObject()! as RenderBox;
          _localPosition = renderObject.globalToLocal(position);
          return _localPosition!;
        },
        onDragEnd: (details) {
          final oldRef = inventory.refAt(index);
          // If the item is still in its original cell, it is still eligible to
          // find a world-space target.  Otherwise, it's been moved somewhere in
          // this inventory.
          if (oldRef?.item != item || oldRef?.origin != index) return;

          final cursor = (details.offset + _localPosition!).toVector2();

          // final center = origin + Vector2.all(ItemWidget.cellSize / 2);
          // Fuck if I know why we need to make a copy of the list, but if I don't
          // this breaks on the 4th item, every time.
          final targetComponents =
              List.from(widget.game.componentsAtPoint(cursor));
          final target = targetComponents.whereType<HasInventory>().firstOrNull;

          for (final inventory in [...?target?.inventories]) {
            if (inventory.canAdd(item)) {
              // Feel free to remove, I simply believe the item will always be
              // coming from this inventory.
              assert(oldRef!.inventory == this.inventory);
              oldRef!.inventory.remove(item);
              inventory.insert(item);
              break;
            }
          }
        },
        feedback: _buildCandidate(context, item),
        childWhenDragging: _buildCandidate(context, item),
        child: itemWidget,
      ),
    );
  }

  Widget _buildCandidate(BuildContext context, Item? item, [CellCoord? coord]) {
    bool? canAdd =
        item != null && coord != null ? inventory.canAdd(item, coord) : null;

    final shape = item?.shape ?? CellShape.unit;
    final size = shape.size;

    return SizedBox(
      width: size.x * InventoryWidget.cellSize,
      height: size.y * InventoryWidget.cellSize,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(
            Colors.white.withOpacity(
              (canAdd ?? false) ? .75 : .25,
            ),
            BlendMode.srcIn),
        child: ItemWidget(item),
      ),
    );
  }
}
