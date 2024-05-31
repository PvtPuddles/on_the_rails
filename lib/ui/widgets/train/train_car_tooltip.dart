import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:on_the_rails/items/inventory.dart';
import 'package:on_the_rails/ui/widgets/inventory.dart';
import 'package:on_the_rails/ui/widgets/menus/tooltip_menu.dart';

export 'package:on_the_rails/ui/widgets/menus/tooltip_menu.dart';

abstract mixin class TrainCarTooltip implements HasTooltip {
  String? get name;

  Inventory? get inventory;

  FlameGame get game;

  @override
  Widget buildTooltip(BuildContext context, TooltipMode mode) {
    final content =
        mode == TooltipMode.persistent ? buildContent(context) : null;
    final inventory =
        mode == TooltipMode.persistent ? buildInventory(context) : null;
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
          if (inventory != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: inventory,
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

  Widget? buildInventory(BuildContext context) {
    if (inventory == null) return null;

    return InventoryWidget(
      inventory!,
      game: game,
    );
  }
}
