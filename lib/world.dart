import 'package:flame/components.dart';
import 'package:on_the_rails/coord.dart';
import 'package:on_the_rails/rails/rail.dart';

export 'package:on_the_rails/coord.dart';

const double cellSize = 128;

class RailWorld extends World {
  RailWorld();

  /// A container holding all the the rails in the game.
  final railMap = RailMap();

  @override
  Future<void> onLoad() async {
    await add(railMap);
  }

  void addRail(Rail rail) {
    railMap.addRail(rail);
  }
}

extension Register<K, T> on Map<K, List<T>> {
  void register(K key, T value) {
    if (containsKey(key)) {
      this[key]!.add(value);
    } else {
      this[key] = [value];
    }
  }
}

extension WorldCoord on CellCoord {
  Vector2 get position => toVector() * cellSize;
}
