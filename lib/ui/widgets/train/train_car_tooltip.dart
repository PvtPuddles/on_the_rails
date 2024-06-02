import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:on_the_rails/items/inventory.dart';
import 'package:on_the_rails/ui/overlays.dart';
import 'package:on_the_rails/ui/widgets/inventory.dart';

abstract mixin class TrainCarTooltip implements HasTooltip {
  String? get name;

  Iterable<Inventory> get inventories;

  FlameGame get game;

  @override
  Widget buildTooltip(BuildContext context, TooltipMode mode) {
    final content =
        mode == TooltipMode.persistent ? buildContent(context) : null;

    return SingleChildScrollView(
      // Prevents jittering while in motion
      physics: const ClampingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildTitle(context, mode),
          if (content != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: content,
            ),
          if (mode == TooltipMode.persistent)
            for (final inventory in inventories)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: buildInventory(context, inventory),
              ),
        ],
      ),
    );
  }

  Widget buildTitle(BuildContext context, TooltipMode mode) {
    return Text(
      name ?? "Train Car",
      style: Theme.of(context).textTheme.titleMedium,
    );
  }

  Widget? buildContent(BuildContext context) {
    return null;
  }

  Widget? buildInventory(BuildContext context, Inventory? inventory) {
    if (inventory == null) return null;
    return Column(
      children: [
        if (inventory.name?.isNotEmpty ?? false)
          Text(inventory.name!, style: Theme.of(context).textTheme.titleSmall),
        InventoryWidget(
          inventory,
          game: game,
        ),
      ],
    );
  }
}
