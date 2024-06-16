part of 'path_builder.dart';

const maxSteps = 400;

/// Cost applied for rails going the wrong direction.
///
/// The [cost] is applied to any rail outside of [minDist]
const wrongDirectionPenalty = (cost: 15, minDist: 2);

class AStarBuilder {
  AStarBuilder({required this.from, required this.to, RailWorld? world})
      : world = world ?? RailWorld()
          ..addRail(from.rail)
          ..addRail(to.rail);

  final RailConnection from;
  final RailConnection to;

  late double fromAngle = from.targetAngle;
  late double toAngle = to.angle;

  late CellCoord toCell = to.coord + to.rail.coord;

  /// A source world containing rails and other obstacles
  final RailWorld world;

  /// Rails we plan to insert into the world
  final RailMap insertions = RailMap();

  late List<RailConnection> openConnections = [from];

  Future<Iterable<Rail>> buildPath() async {
    int steps = 0;
    print("Begin");
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
      print("Error building path: $e");
      rethrow;
    }
    final lastConnection = openConnections.single;
    final rawPath = _pathOf(lastConnection).toList();
    print("Built path in $steps steps (${rawPath.length})");
    return cleanPath(rawPath.reversed);
  }

  Iterable<Rail> cleanPath(Iterable<Rail> path) sync* {
    for (final rail in path) {
      if (rail == from.rail) continue;
      if (rail == to.rail) continue;

      for (final c in [rail.startingConnection, rail.endingConnection]) {
        c.activeConnection = null;
        c.connections = [];
      }
      yield rail;
    }
  }

  Future<bool> step() async {
    final next = openConnections.removeAt(0);
    final added = await addOptionsFrom(next);

    if (openConnections.isEmpty) {
      throw Exception("Pathfinding failed.  No more paths to try");
    }
    for (final newConnection in added) {
      final target = newConnection.targetCell;
      if (target == to.coord + to.rail.coord &&
          newConnection.targetAngle == to.angle) {
        print("...?");
        openConnections = [newConnection];
        return true;
      }
    }
    return false;
  }

  Future<List<RailConnection>> addOptionsFrom(RailConnection connection) async {
    final angle = connection.targetAngle;
    final coord = connection.targetCell;

    final List<Rail> allOptions = [
      ...PathBuilder.straights.map(
        (builder) => builder.$1.call(angle: angle, coord: coord),
      ),
      ...PathBuilder.bends.expand((builder) {
        final bend = builder.$1.call(angle: angle, coord: coord);
        return [bend, bend.flipped];
      }),
    ];

    /// Returns the newly created connection from a rail coming from this
    /// [connection].
    RailConnection newConnectionOf(Rail rail) {
      final connection = [rail.endingConnection, rail.startingConnection]
          .firstWhere((c) => c.angle == angle);
      return connection.partner;
    }

    /// Rails that are not already inserted
    Iterable<Rail> options =
        allOptions.whereNot((rail) => insertions[rail.coord].contains(rail));

    // TODO : Find rails in [world] and add explore them too, even if we don't
    //  add a rail
    // Remove options that lead to a rail we've already been to
    options = options.where((rail) {
      final connection = newConnectionOf(rail);
      final targetCell = connection.targetCell;

      // Don't exclude connections that complete the path :)
      if (targetCell == toCell && connection.targetAngle == to.angle) {
        return true;
      }

      final rails = [...world.railMap[targetCell], ...insertions[targetCell]];
      final connections = rails
          .expand((rail) => [rail.startingConnection, rail.endingConnection]);
      final matchingConnection = connections.firstWhereOrNull((c) =>
          c.targetCell == connection.coord + connection.rail.coord &&
          c.angle == connection.targetAngle);
      return matchingConnection == null;
    });

    final toInsert = options.toList(); // Not sure why but if this is left as an
    // iterable it empties itself out.

    await insertions.addAllRails(toInsert);
    final newConnections = toInsert.map(newConnectionOf);
    openConnections.addAll(newConnections);

    openConnections = openConnections.sortedBy<num>(heuristic);
    return newConnections.toList();
  }

  double heuristic(RailConnection connection) {
    // TODO : Add a penalty based on the speed limit of the rail.  IE. bends
    //  will be heavily dis-favored since they require sharp turns.

    var path = _pathOf(connection);
    if (_pathCache[connection] == null) {
      _pathCache[connection] ??= path.toList();
    }
    // Only grab the rails we're adding; existing rails don't count towards the
    // heuristic
    path = path.whereNot((rail) => world.railMap[rail.coord].contains(rail));

    final lengthPenalty = .5 * path.totalLength / cellSize;

    final endPos = (to.coord + to.rail.coord).toVector();
    final currPos = (connection.coord + connection.rail.coord).toVector();
    final distancePenalty = currPos.distanceTo(endPos);

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

    final totalPenalty = turnPenalty + lengthPenalty + distancePenalty;
    return totalPenalty;
  }

  final Map<RailConnection, List<Rail>> _pathCache = {};

  /// Backtracks along the rail to find the original [from] rail.
  Iterable<Rail> _pathOf(RailConnection connection) sync* {
    if (_pathCache[connection] != null) {
      yield* _pathCache[connection]!;
      return;
    }

    RailConnection from = connection;
    Rail current = from.rail;

    yield current;
    while (current != this.from.rail) {
      final partner = from.partner;
      RailConnection? activeConnection = partner.activeConnection;
      if (partner.activeConnection == null) {
        activeConnection = _connectionFromMap(partner);
      }
      assert(
          activeConnection != null, "Hit a dead end looking for ${this.from}");
      from = activeConnection!;
      current = from.rail;
      if (_pathCache[from] != null) {
        yield* _pathCache[from]!;
        return;
      }
      yield current;
    }
    yield from.rail;
  }

  RailConnection? _connectionFromMap(RailConnection connection) {
    final targetCell = connection.targetCell;
    final rails = world.railMap[targetCell];
    final connections = rails
        .expand((rail) => [rail.startingConnection, rail.endingConnection]);
    return connections
        .firstWhereOrNull((c) => c.angle == connection.targetAngle);
  }
}

extension PathLength on Iterable<Rail> {
  double get totalLength => map((rail) => rail.metric.length).sum;
}
