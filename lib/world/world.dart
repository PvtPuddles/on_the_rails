import 'dart:math';

import 'package:flame/components.dart';
import 'package:on_the_rails/agents/path_builders/path_builder.dart';
import 'package:on_the_rails/agents/user_agent.dart';
import 'package:on_the_rails/components/buildings/platform.dart';
import 'package:on_the_rails/components/buildings/poi.dart';
import 'package:on_the_rails/components/rails/shapes.dart';
import 'package:on_the_rails/components/train/train.dart';
import 'package:on_the_rails/coord.dart';
import 'package:on_the_rails/items/inventory.dart';

export 'package:on_the_rails/coord.dart';

const double cellSize = 96;

const worldScale = cellSize / 32;

final _origin = Straight1(coord: const CellCoord(-2, -5));

final _rails = [
  Straight1(coord: const CellCoord(-3, -5)),
  // Straight1(coord: const CellCoord(-0, -4)),

  _origin,

  Straight1(coord: const CellCoord(4, 3), angle: -pi / 2),
];

class RailWorld extends World {
  RailWorld();

  /// A container holding all the the rails in the game.
  final railMap = RailMap();

  /// A container holding all the the points-of-interest in the game.
  final poiMap = PoiMap();

  /// A manually run a star algorithm
  late final aStar = AStarBuilder(
    from: _rails.first.endingConnection,
    to: _rails.last.startingConnection,
    world: RailWorld()..addAllRails(_rails),
  );

  final platforms = [
    Platform(
      name: "Nor'easter",
      coord: const CellCoord(6, -6),
      length: 3,
      inventory: Inventory(width: 4, height: 2),
    ),
    Platform(
      name: "Sou'wester",
      coord: const CellCoord(-6, 3),
      length: 3,
      angle: -pi / 2,
      inventory: Inventory(width: 5, height: 3),
    )
  ];

  @override
  Future<void> onLoad() async {
    await add(railMap);
    await add(poiMap);

    for (final rail in _rails) {
      addRail(rail);
    }

    final uAgent = UserAgent.instance;
    add(uAgent);

    final railsByPlatform = <Platform, List<Rail>>{};
    for (final platform in platforms) {
      await poiMap.add(platform);

      List<Rail> railsOf(Platform platform) {
        List<Rail> rails = [];
        for (final cell in platform.shape.cells) {
          final dirToRail = (const CellCoord(0, 1)).rotate(platform.angle);
          if (platform.shape.cells.contains(cell + dirToRail)) continue;
          rails.add(Straight1(
            angle: platform.angle,
            coord: cell + dirToRail + platform.coord,
          ));
        }
        return rails;
      }

      railsByPlatform[platform] = railsOf(platform);
      await railMap.addAllRails([...?railsByPlatform[platform]]);
    }

    try {
      final path = await AStarBuilder(
              from: _origin.endingConnection,
              to: platforms.first.rails.first.startingConnection)
          .buildPath();
      await railMap.addAllRails(path);
    } catch (_) {}
    try {
      final path = await AStarBuilder(
              from: platforms.last.rails.last.endingConnection,
              to: _origin.startingConnection)
          .buildPath();
      await railMap.addAllRails(path);
    } catch (_) {}

    (RailConnection, RailConnection)? endsOf(Platform platform) {
      final rails = railsByPlatform[platform];
      if (rails == null || rails.isEmpty) return null;
      return (rails.first.startingConnection, rails.last.endingConnection);
    }

    for (final (index, platform) in platforms.indexed) {
      final ends = endsOf(platform);
      if (ends == null) continue;
      final (_, end) = ends;

      final otherPlatforms = [
        ...platforms.skip(index + 1),
        ...platforms.take(index)
      ].where((p) => endsOf(p) != null);
      final other = otherPlatforms.firstOrNull;
      if (other == null) continue;
      final (oStart, _) = endsOf(other)!;

      try {
        final path =
            await AStarBuilder(from: end, to: oStart, world: this).buildPath();
        await railMap.addAllRails(path);
      } catch (_) {}
    }

    /// First to last
    try {
      final path = await AStarBuilder(
              from: _rails.first.endingConnection,
              to: _rails.last.startingConnection)
          .buildPath();
      await railMap.addAllRails(path);
    } catch (_) {}

    /// Last to first
    try {
      final path = await AStarBuilder(
              from: _rails.last.endingConnection,
              to: _rails.first.startingConnection)
          .buildPath();
      await railMap.addAllRails(path);
    } catch (_) {}

    final train = Train(
      agent: uAgent,
      cars: [
        buildHandCart(),
        // ...buildJupiter(),
      ],
    );
    uAgent.focus = train.cars.first;
    train.rail = _origin;
    add(train);
  }

  Future<void> addRail(Rail rail) {
    return railMap.addRail(rail);
  }

  Future<void> addAllRails(Iterable<Rail> rails) {
    return railMap.addAllRails(rails);
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

  bool unregister(K key, T value) {
    return this[key]?.remove(value) ?? false;
  }
}

extension WorldCoord on CellCoord {
  Vector2 get position => toVector() * cellSize;
}
