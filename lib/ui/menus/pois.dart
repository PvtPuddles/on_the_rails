import 'package:flutter/material.dart';
import 'package:frosted_glass/frosted_glass.dart';
import 'package:on_the_rails/components/buildings/poi.dart';
import 'package:on_the_rails/items/inventory.dart';
import 'package:on_the_rails/ui/menus/menu.dart';
import 'package:on_the_rails/ui/widgets/inventory.dart';

class PoiManager extends MenuManager<Poi> {
  PoiManager(super.game);

  Set<Poi> _pois = {};

  static const String name = "PointsOfInterest";

  @override
  String overlayName = name;

  @override
  Widget buildMenu(BuildContext context) {
    return ConstrainedBox(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height),
      child: SingleChildScrollView(
        child: Column(
          children: [
            for (final poi in _pois)
              FrostedGlass(
                frostColor: frostColor,
                child: Builder(builder: (context) {
                  return Column(
                    children: [
                      Text(
                        poi.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (poi is HasInventory)
                        for (final inv in (poi as HasInventory).inventories)
                          InventoryWidget(inv, game: game)
                    ],
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void add(Poi element) {
    _pois.add(element);
    super.add(element);
  }

  void set(Iterable<Poi> elements) {
    game.overlays.add(overlayName);
    notifyListeners();
    _pois = elements.toSet();
  }

  @override
  void dismiss() {
    _pois = {};
    super.dismiss();
  }
}

class PoisMenu extends StatelessWidget {
  const PoisMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
