import 'package:flutter/material.dart';
import 'package:on_the_rails/app.dart';
import 'package:on_the_rails/ui/menus/menu.dart';
import 'package:on_the_rails/ui/menus/pois.dart';

export 'menus/pois.dart';
export 'menus/tooltip_menu.dart';

final gameOverlays = {
  // TODO : Convert tooltip overlay to MenuManager
  // "tooltipOverlay": (context, game) => TooltipOverlay(camera: game.camera),
  PoiManager.name: (BuildContext context, OnTheRails game) => Menu(
        manager: game.poiManager,
        positionBuilder: (context, child) =>
            Positioned(bottom: 0, child: child),
      ),
};
