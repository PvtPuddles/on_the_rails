part of 'path_builder.dart';

const maxSteps = 500;

/// Cost applied for rails going the wrong direction.
///
/// The [cost] is applied to any rail outside of [minDist].
///
/// Generally speaking, the higher the cost, the fewer iterations the algorithm
/// takes, though the less the algorithm is willing to follow existing paths,
/// and instead will take diagonals.
const wrongDirectionPenalty = (cost: 5, minDist: 3);

/// Multiplier applied to discount existing rails in path building.
///
/// The lower this number, the more eager the algorithm is to share rails, even
/// at the cost of total route length.
const prebuiltModifier = .25;

/// Modifier applied to the end point's distance from the target.
///
/// The larger this value, the more the algorithm is penalized for exploring
/// nodes far away from the destination.
const distanceModifier = sqrt2;

class AStarBuilder {
  AStarBuilder({required this.from, required this.to, RailWorld? world})
      : world = world ??
            (RailWorld()
              ..addRail(from.rail)
              ..addRail(to.rail));

  final RailConnection from;
  final RailConnection to;

  late double fromAngle = from.targetAngle;
  late double toAngle = to.angle;

  late CellCoord toCell = to.coord + to.rail.coord;

  /// A source world containing rails and other obstacles
  final RailWorld world;

  /// Nodes we plan to insert
  late final NodeMap insertions = NodeMap()
    ..add(PathNode.to(from.rail, end: from));

  late List<RailConnection> openConnections = [from];

  late List<PathNode> nodesToExplore = [PathNode.to(from.rail, end: from)];

  Future<Iterable<Rail>> buildPath() async {
    int steps = 0;
    try {
      bool found = false;
      do {
        steps++;
        found = await step();
        if (!found && steps > maxSteps) {
          throw Exception("Could not find path in $maxSteps steps");
        }
      } while (!found);
    } catch (e) {
      debugPrint("Error building path: $e");
      rethrow;
    }
    final lastNode = nodesToExplore.single;
    late List<Rail> rawPath;
    try {
      rawPath = _pathOf(lastNode).toList();
    } on StateError catch (_) {
      rethrow;
    }
    debugPrint("Found path in $steps steps");
    return cleanPath(rawPath.reversed);
  }

  Iterable<Rail> cleanPath(Iterable<Rail> path) sync* {
    for (final rail in path) {
      if (rail == from.rail) {
        continue;
      }
      if (rail == to.rail) continue;
      // Exclude rails that were already in the world
      if (world.railMap[rail.coord].contains(rail)) continue;

      for (final c in [rail.startingConnection, rail.endingConnection]) {
        c.activeConnection = null;
        c.connections = [];
      }
      yield rail;
    }
  }

  Future<bool> step() async {
    final next = nodesToExplore.removeAt(0);
    final added = await addOptionsFrom(next);

    if (nodesToExplore.isEmpty) {
      throw Exception("Pathfinding failed.  No more nodes to try");
    }

    bool isWinner(PathNode node) {
      final target = node.end.targetCell;
      return (target == to.coord + to.rail.coord &&
          node.end.targetAngle == to.angle);
    }

    final winner = added.firstWhereOrNull(isWinner);

    if (winner != null) {
      nodesToExplore = [winner];
      return true;
    }

    return false;
  }

  Future<List<PathNode>> addOptionsFrom(PathNode node) async {
    final angle = node.end.targetAngle;
    final coord = node.end.targetCell;

    final List<PathNode> allOptions = [
      ...PathBuilder.straights.map(
        (builder) {
          final rail = builder.$1.call(angle: angle, coord: coord);
          return PathNode(rail, start: rail.startingConnection);
        },
      ),
      ...PathBuilder.bends.expand((builder) {
        final bend = builder.$1.call(angle: angle, coord: coord);
        final flipped = bend.flipped;
        return [
          PathNode(bend, start: bend.startingConnection),
          PathNode(flipped, start: flipped.endingConnection),
        ];
      }),
    ];

    Iterable<PathNode> options = allOptions.whereNot((node) {
      const exclude = true;

      /// Remove nodes that are already in the path
      if (insertions[node.startCoord].contains(node)) return exclude;

      /// Remove nodes that lead to somewhere we've already visited, unless its
      /// a shortcut.
      final exploredNodes = insertions.map.values.flattened;
      final duplicate = exploredNodes.firstWhereOrNull((other) {
        return other.end._info == node.end._info;
      });
      if (duplicate != null) {
        final dupePath = _pathOf(duplicate);
        final ourPath = _pathOf(node).toList();
        _pathCache[node] = ourPath;

        // Found a shortcut, remove duplicate
        if (lengthOf(dupePath) > lengthOf(ourPath)) {
          insertions.remove(duplicate);
        } else {
          return exclude;
        }
      }

      return !exclude;
    });

    options = options.map((PathNode node) {
      bool isDuplicateOf(Rail rail) {
        final other =
            (start: rail.startingConnection, end: rail.endingConnection);
        if (node.start._info == other.start._info &&
            node.end._info == other.end._info) return true;
        if (node.start._info == other.end._info &&
            node.end._info == other.start._info) return true;
        return false;
      }

      final duplicateNode =
          insertions[node.startCoord].firstWhereOrNull((other) {
        assert(node != other);
        return isDuplicateOf(other.rail);
      });
      if (duplicateNode != null) {
        return PathNode(duplicateNode.rail, start: duplicateNode.end);
      }
      final duplicateRail =
          world.railMap[node.startCoord].firstWhereOrNull(isDuplicateOf);
      if (duplicateRail != null) {
        bool reversed =
            node.start._info != duplicateRail.startingConnection._info;
        return PathNode(
          duplicateRail,
          start: reversed
              ? duplicateRail.endingConnection
              : duplicateRail.startingConnection,
        );
      }

      return node;
    });

    // Not sure why but if this is left as an iterable it empties itself out.
    final toInsert = options.toList();

    insertions.addAll(toInsert);
    nodesToExplore.addAll(toInsert);

    try {
      nodesToExplore = nodesToExplore.sortedBy<num>(heuristic);
    } on StateError catch (_) {
      debugPrint(
          "Failed to sort rails;\n${RailMap.drawRails(toInsert.map((n) => n.rail))}");
      rethrow;
    }
    return toInsert;
  }

  double heuristic(PathNode node) {
    // TODO : Add a penalty based on the speed limit of the rail.  IE. bends
    //  will be heavily dis-favored since they require sharp turns.

    final connection = node.end;
    var path = _pathOf(node);
    if (_pathCache[node] == null) {
      _pathCache[node] ??= path.toList();
    }

    final lengthPenalty = lengthOf(path) / cellSize;

    final endPos = (to.coord + to.rail.coord).toVector();
    final currPos = (connection.coord + connection.rail.coord).toVector();
    var distancePenalty = currPos.distanceTo(endPos);

    final directionToTarget =
        (toCell - (connection.coord + connection.rail.coord))
            .toOffset()
            .direction;
    final angleDelta =
        PathBuilder.angleBetween(directionToTarget, connection.targetAngle)
            .abs();
    final turns = angleDelta / (pi / 2);
    final turnPenalty = distancePenalty > wrongDirectionPenalty.minDist
        ? turns * wrongDirectionPenalty.cost
        : 0;

    final totalPenalty =
        turnPenalty + lengthPenalty + (distanceModifier * distancePenalty);
    return totalPenalty;
  }

  final Map<PathNode, List<Rail>> _pathCache = {};

  /// Backtracks along the rail to find the original [from] rail.
  Iterable<Rail> _pathOf(PathNode node) sync* {
    if (_pathCache[node] != null) {
      yield* _pathCache[node]!;
      return;
    }

    yield node.rail;

    if (node.rail == from.rail) return;

    final previous = insertions.nodeOf(node, backTrack: true);
    assert(previous != node);
    if (previous == null) {
      throw StateError(
        "Hit a dead end back-tracking from ${node.start} to $from",
      );
    }
    yield* _pathOf(previous);
  }

  double lengthOf(Iterable<Rail> path) {
    double total = 0;
    for (final rail in path) {
      double length = rail.metric.length;

      bool inWorld = world.railMap[rail.coord].contains(rail);
      if (inWorld) {
        length *= prebuiltModifier;
      }

      total += length;
    }
    return total;
  }
}

typedef _ConnectionInfo = ({CellCoord coord, double targetAngle});

extension _Info on RailConnection {
  _ConnectionInfo get _info =>
      (coord: coord + rail.coord, targetAngle: targetAngle);
}

class PathNode {
  PathNode(this.rail, {required this.start})
      : end = start == rail.startingConnection
            ? rail.endingConnection
            : rail.startingConnection;

  PathNode.to(this.rail, {required this.end})
      : start = end == rail.endingConnection
            ? rail.startingConnection
            : rail.endingConnection;

  final Rail rail;

  final RailConnection start;
  final RailConnection end;

  late final CellCoord startCoord = start.coord + start.rail.coord;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PathNode) return false;
    return (start._info, end._info) == (other.start._info, other.end._info);
  }

  @override
  int get hashCode => Object.hashAll([start._info, end._info]);

  @override
  String toString() {
    return "$end";
  }
}

class NodeMap {
  NodeMap();

  Map<CellCoord, List<PathNode>> map = {};

  List<PathNode> operator [](CellCoord coord) {
    return [...?map[coord]];
  }

  void addAll(Iterable<PathNode> nodes) {
    for (final node in nodes) {
      add(node);
    }
  }

  void add(PathNode node) {
    // Register rail at each cell
    for (final cell in node.rail.shape
        .transform(node.rail.coord, angle: node.rail.angle)
        .cells) {
      map.register(cell, node);
    }
  }

  bool remove(PathNode node) {
    // Remove rail from each cell
    bool removed = true;
    for (final cell in node.rail.shape
        .transform(node.rail.coord, angle: node.rail.angle)
        .cells) {
      removed &= map.unregister(cell, node);
    }
    return removed;
  }

  PathNode? nodeOf(PathNode node, {bool backTrack = false}) {
    final connection = backTrack ? node.start : node.end;
    final nodes = this[connection.targetCell];
    final info = connection._info;
    final found = nodes.firstWhereOrNull((node) {
      final oConnection = backTrack ? node.end : node.start;
      final oInfo = oConnection._info;
      if (oInfo.coord == connection.targetCell &&
          oConnection.angle == info.targetAngle) {
        return true;
      }
      return false;
    });
    return found;
  }

  String draw() {
    final rails = map.values.flattened.map((n) => n.rail).toList();
    if (rails.isEmpty) return "";

    return RailMap.drawRails(rails, map.map((coord, nodes) {
      return MapEntry(coord, nodes.map((n) => n.rail).toList());
    }));
  }

  static String drawRails(Iterable<Rail> rails,
      [Map<CellCoord, List<Rail>>? map]) {
    if (map == null) {
      map = <CellCoord, List<Rail>>{};
      for (final rail in rails) {
        for (final cell
            in rail.shape.transform(rail.coord, angle: rail.angle).cells) {
          map.register(cell, rail);
        }
      }
    }

    final cells = rails
        .expand(
            (rail) => rail.shape.transform(rail.coord, angle: rail.angle).cells)
        .toList();
    final worldShape = CellShape(cells);
    final (min, max) = worldShape.bounds;
    final yRange = max.y - min.y + 1;
    final xRange = max.x - min.x + 1;
    List<List<String>> shapes = List.generate(
      yRange,
      (index) => List.filled(xRange, "  "),
    );
    for (int y = 0; y <= yRange; y++) {
      for (int x = 0; x <= xRange; x++) {
        final coord = CellCoord(x + min.x, max.y - y);
        final rails = map[coord];
        if (rails?.isEmpty ?? true) continue;
        rails!;
        if (rails.length > 1) {
          shapes[y][x] = "▣ ";
        } else if (rails.single.coord != coord) {
          shapes[y][x] = "▢ ";
        } else {
          shapes[y][x] = switch (rails.single.angle) {
            < pi / 2 => "▷ ",
            < pi => "△ ",
            < 3 * pi / 2 => "◁ ",
            _ => "▽ ",
          };
        }
      }
    }
    return shapes.map((row) => row.join()).join("\n");
  }
}
