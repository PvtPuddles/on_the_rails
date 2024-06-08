import 'dart:math';

import 'package:flame/components.dart';
import 'package:on_the_rails/agents/user_agent.dart';
import 'package:on_the_rails/components/buildings/platform.dart';
import 'package:on_the_rails/components/buildings/poi.dart';
import 'package:on_the_rails/components/rails/layouts.dart';
import 'package:on_the_rails/components/rails/rail.dart';
import 'package:on_the_rails/components/train/train.dart';
import 'package:on_the_rails/coord.dart';
import 'package:on_the_rails/items/inventory.dart';

export 'package:on_the_rails/coord.dart';

const double cellSize = 96;

const worldScale = cellSize / 32;

final _rails = Layouts.cloverPlus;

class RailWorld extends World {
  RailWorld();

  /// A container holding all the the rails in the game.
  final railMap = RailMap();

  /// A container holding all the the points-of-interest in the game.
  final poiMap = PoiMap();

  @override
  Future<void> onLoad() async {
    await add(railMap);
    await add(poiMap);

    for (final rail in _rails) {
      addRail(rail);
    }

    final uAgent = UserAgent.instance;
    add(uAgent);

    final train = Train(
      agent: uAgent,
      cars: [
        ...buildJupiter(),
      ],
    );
    uAgent.focus = train.cars.first;
    train.rail = _rails.elementAtOrNull(4);
    add(train);

    poiMap.add(Platform(
      name: "Nor'easter",
      coord: const CellCoord(1, -4),
      length: 2,
      inventory: Inventory(width: 4, height: 2),
    ));
    poiMap.add(Platform(
      name: "Sou'wester",
      coord: const CellCoord(-4, 1),
      length: 2,
      angle: -pi / 2,
      inventory: Inventory(width: 5, height: 3),
    ));
  }

  void addRail(Rail rail) {
    railMap.addRail(rail);
  }

  void addPoi(Poi poi) {
    poiMap.add(poi);
  }

  List<Object> operator [](CellCoord coord) {
    return [
      ...railMap[coord],
      ...poiMap[coord],
    ];
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
