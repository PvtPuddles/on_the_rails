// @formatter:off
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/foundation.dart';
import 'package:on_the_rails/agents/user_agent.dart';
import 'package:on_the_rails/rails/layouts.dart';
import 'package:on_the_rails/rails/rail.dart';
import 'package:on_the_rails/train/train.dart';
import 'package:on_the_rails/world.dart';
// @formatter:on

const trailingDistance = 80;

final _rails = Layouts.cloverPlus;

class OnTheRails extends FlameGame<RailWorld>
    with HasKeyboardHandlerComponents {
  OnTheRails() : super(world: RailWorld());

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

    final agent = UserAgent();
    world.add(agent);

    _addRails();
    final train = Train(
      agent: agent,
      cars: [
        TrainCar(length: 100, riderSpacing: 50, debugLabel: "first"),
        TrainCar.single(length: 50, debugLabel: "mid  "),
        TrainCar(length: 100, riderSpacing: 50, debugLabel: "last "),
      ],
    );
    train.rail = _rails.elementAtOrNull(4);
    world.add(train);
  }

  void _addRails() {
    for (final rail in _rails) {
      world.addRail(rail);
    }
  }
}
