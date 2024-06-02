// @formatter:off
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:on_the_rails/priorities.dart';
import 'package:on_the_rails/rails/rail_connection.dart';
import 'package:on_the_rails/world.dart';

import '../components/path_component.dart';
import 'bend.dart' as bend;
import 'straight.dart' as straight;

export 'package:flutter/material.dart';
// @formatter:on

const drawCells = false;
const drawDirections = false;
const drawPaths = false;

const allRails = [
  ...bend.rails,
  ...straight.rails,
];

const gauge = cellSize / 4;

abstract class Rail extends SpriteComponent with HasGameReference {
  Rail({
    super.key,
    required this.name,
    required this.shape,
    required this.coord,
    super.angle,
    super.nativeAngle,
  }) : super(
          position: coord.position,
          size: sizeOf(shape),
          anchor: shape.anchor,
          priority: Priority.rail,
        ) {
    if (kDebugMode) addAll(debugComponents());
  }

  final String name;

  final CellCoord coord;

  /// The cells that this rail covers, relative to the anchor cell (0, 0)
  final CellShape shape;

  RailConnection get startingConnection;
  RailConnection get endingConnection;

  RailMap get _map => (game.world as RailWorld).railMap;

  late final SpriteComponent _ties;
  late final SpriteComponent _sleeper;

  @override
  void onLoad() {
    const double tileWidth = 32;
    const multiplier = tileWidth / cellSize;
    final bounds = size * multiplier;
    final sheet = SpriteSheet(
      image: game.images.fromCache("rails/$name.png"),
      srcSize: bounds,
      spacing: 1,
    );

    sprite = sheet.getSpriteById(0);
    final ties = sheet.getSpriteById(1);
    final sleeper = sheet.getSpriteById(2);
    final components = ([
      ties,
      sleeper,
    ].map((e) => SpriteComponent(
          sprite: e,
          size: size,
          anchor: anchor,
          position: position,
          angle: angle,
        ))).toList();

    _ties = components[0];
    _sleeper = components[1];
  }

  @override
  void onMount() {
    _map.mount(this);
    super.onMount();
  }

  @override
  void onRemove() {
    _map.mount(this);
    super.onRemove();
  }

  @visibleForTesting
  static (CellCoord, CellCoord) boundsOf(CellShape shape) {
    assert(shape.cells.any((cell) => cell.x == 0 && cell.y == 0));
    final bounds = shape.bounds;
    assert(bounds.$1.x <= 0 && bounds.$2.x >= 0);
    assert(bounds.$1.y <= 0 && bounds.$2.y >= 0);
    return bounds;
  }

  @visibleForTesting
  static Vector2 sizeOf(CellShape shape) {
    final bounds = boundsOf(shape);
    final min = bounds.$1;
    final max = bounds.$2;
    final size = Vector2(
      (max.x - min.x) + 1,
      (max.y - min.y) + 1,
    );
    size.multiply(Vector2.all(cellSize));
    return size;
  }

  /// Local-space path describing this rail
  late final Path path = buildPath();
  late final PathMetric metric = path.computeMetrics().single;

  Tangent tangentForOffset(double distance) {
    assert(distance >= 0 && distance <= metric.length);
    final tangent = metric.getTangentForOffset(distance)!;

    final origin = metric.getTangentForOffset(0)!;

    final anchorOffset = Offset.fromDirection(angle, cellSize / 2);
    final localPosition = tangent.position - origin.position;
    final rotatedPos = localPosition.toVector2()..rotate(angle);
    return Tangent((rotatedPos + position).toOffset() - anchorOffset,
        Offset.fromDirection(tangent.angle - angle));
  }

  @protected
  Path buildPath();

  List<PositionComponent> debugComponents() {
    return [
      RailPath(path, position: Vector2.zero()),
    ];
  }
}

class RailPath extends PathComponent {
  RailPath(super.path, {required super.position})
      : super(
          priority: Priority.rail - 1,
        );

  @override
  void render(Canvas canvas) {
    if (kDebugMode && drawPaths) {
      super.render(canvas);
    }
  }
}

class RailCell extends SpriteComponent with HasGameReference {
  RailCell({
    required super.position,
  })  : name = "rail_cell",
        super(
          priority: Priority.sleeper + 1,
          size: Vector2.all(cellSize),
          anchor: Anchor.center,
        );

  RailCell.occupied({
    required super.position,
  })  : name = "rail_cell_occupied",
        super(
          priority: Priority.sleeper + 1,
          size: Vector2.all(cellSize),
          anchor: Anchor.center,
        );

  RailCell.origin({
    required super.position,
    required super.angle,
  })  : name = "rail_segment_start",
        super(
          priority: Priority.sleeper + 1,
          size: Vector2.all(cellSize),
          anchor: Anchor.center,
        );

  String name;

  @override
  void onLoad() {
    sprite = Sprite(game.images.fromCache("rails/debug/$name.png"));
  }

  @override
  void render(Canvas canvas) {
    if (kDebugMode && drawCells) {
      super.render(canvas);
    }
  }
}

class RailMap extends Component {
  RailMap();

  final _railLayer = Component(priority: Priority.rail);
  final _tieLayer = Component(priority: Priority.ties);
  final _sleeperLayer = Component(priority: Priority.sleeper);

  @override
  Future<void> onLoad() async {
    await addAll([_railLayer, _tieLayer, _sleeperLayer]);
  }

  Map<CellCoord, List<Rail>> rails = {};

  Map<CellCoord, List<RailConnection>> connections = {};

  Future<void> addRail(Rail rail) async {
    // Add debug cells to world
    if (kDebugMode) {
      for (final cell in rail.shape.cells) {
        bool isRailOrigin = cell.x == 0 && cell.y == 0;
        final v2 = cell.toVector();
        v2.rotate(rail.angle);
        v2.multiply(Vector2.all(cellSize));
        v2.add(rail.position);
        if (isRailOrigin) {
          add(RailCell.origin(position: v2, angle: rail.angle));
        } else {
          add(RailCell(position: v2));
        }
      }
    }

    // Add rail itself
    rails.register(rail.coord, rail);
    connections.addConnection(rail.startingConnection);
    connections.addConnection(rail.endingConnection);

    await _railLayer.add(rail);
    _railLayer.add(rail.startingConnection);
    _railLayer.add(rail.endingConnection);
  }

  Future<void> mount(Rail rail) async {
    await _tieLayer.add(rail._ties);
    await _sleeperLayer.add(rail._sleeper);
  }

  void dismount(Rail rail) {
    _tieLayer.remove(rail._ties);
    _sleeperLayer.remove(rail._sleeper);
  }
}
