// @formatter:off
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:on_the_rails/components/rails/rail.dart';
import 'package:on_the_rails/ui/overlays.dart';
import 'package:on_the_rails/world/world.dart';
// @formatter:on

const trailingDistance = 80;

class OnTheRails extends FlameGame<RailWorld>
    with HasKeyboardHandlerComponents, TapDetector {
  OnTheRails({super.camera}) : super(world: RailWorld());

  @override
  Future<void> onLoad() async {
    await images.loadAll([
      ...allRails.map((e) => "rails/$e.png"),
      if (kDebugMode)
        ...[
          "rider",
          "rail_cell",
          "rail_cell_occupied",
          "rail_connection",
          "rail_segment_start",
        ].map((e) => "rails/debug/$e.png"),
    ]);
    camera.viewfinder.anchor = Anchor.center;

    overlays.addEntry(
        "tooltipOverlay", (context, game) => TooltipOverlay(camera: camera));
    overlays.add("tooltipOverlay");
  }

  late final poiManager = PoiManager(this);
}
