import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:on_the_rails/rails/bend.dart';
import 'package:on_the_rails/rails/rail.dart';
import 'package:on_the_rails/rails/straight.dart';

class OnTheRails extends FlameGame {
  OnTheRails();

  final _rails = [
    Bend2x2(position: Vector2(0, cellSize.y * -1)),
    Straight1x1(position: Vector2(0, 0)),
    Straight1x1(position: Vector2(0, cellSize.y * 1)),
  ];

  @override
  Future<void> onLoad() async {
    await images.loadAll([
      ...allRails.map((e) => "rails/$e.png"),
    ]);

    camera.viewfinder.anchor = Anchor.center;

    world.addAll(_rails);
  }
}
