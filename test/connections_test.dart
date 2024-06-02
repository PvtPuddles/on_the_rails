import 'dart:math';

import 'package:flame/game.dart' as fg;
import 'package:flutter_test/flutter_test.dart';
import 'package:on_the_rails/components/rails/shapes.dart';
import 'package:on_the_rails/world/world.dart';

void main() {
  int degrees(double rads) => fg.degrees(rads).round() % 360;

  group("Connections", () {
    group("Angled Correctly", () {
      test("- Straight1x1", () {
        final rail = Straight1x1(coord: CellCoord.zero);
        expect(degrees(RailConnection.directionToCenter(rail, true)), 0);
        expect(degrees(RailConnection.directionToCenter(rail, false)), 180);

        for (final double angle in [0, pi / 2, pi, 3 * pi / 2]) {
          final rail = Straight1x1(coord: CellCoord.zero, angle: angle);
          final start = degrees(angle);
          final end = degrees(angle + pi);
          expect(degrees(rail.startingConnection.angle), start,
              reason: "Failed angle $angle");
          expect(degrees(rail.startingConnection.railDirection), start,
              reason: "Failed angle $angle");
          expect(degrees(rail.endingConnection.angle), end,
              reason: "Failed angle $angle");
          expect(degrees(rail.endingConnection.railDirection), end,
              reason: "Failed angle $angle");
        }
      });

      test("- Bend2x2", () {
        final path = Bend2x2.pathTemplate();
        final metric = path.computeMetrics().single;
        final start = metric.getTangentForOffset(0)!.position;
        final center = metric.getTangentForOffset(metric.length / 2)!.position;
        final railAngle = degrees((center - start).direction.abs());

        final rail = Bend2x2(coord: CellCoord.zero);
        expect(degrees(RailConnection.directionToCenter(rail, true)),
            360 - railAngle);
        expect(degrees(RailConnection.directionToCenter(rail, false)),
            (90 + railAngle) % 360);

        for (final double angle in [0, pi / 2, pi, 3 * pi / 2]) {
          final rail = Bend2x2(coord: CellCoord.zero, angle: angle);
          final start = degrees(angle);
          final startAngle = (start - railAngle) % 360;
          final end = degrees(angle + pi / 2);
          final endAngle = (end + railAngle) % 360;

          expect(degrees(rail.startingConnection.angle), start,
              reason: "Failed angle $angle");
          expect(degrees(rail.startingConnection.railDirection), startAngle,
              reason: "Failed angle $angle");
          expect(degrees(rail.endingConnection.angle), end,
              reason: "Failed angle $angle");
          expect(degrees(rail.endingConnection.railDirection), endAngle,
              reason: "Failed angle $angle");
        }
      });
    });

    group("Active Connections", () {
      test("- Straight1x1", () {
        const coord1 = CellCoord.zero;
        final rail1 = Straight1x1(coord: coord1);
        expect(rail1.startingConnection.coord, coord1);
        expect(rail1.endingConnection.coord, coord1);

        final ConnectionMap map = {};
        map.addConnection(rail1.startingConnection);
        expect(map[CellCoord.zero], [rail1.startingConnection]);
        map.addConnection(rail1.endingConnection);
        expect(map[CellCoord.zero],
            [rail1.startingConnection, rail1.endingConnection]);

        const coord2 = CellCoord(1, 0);
        final rail2 = Straight1x1(coord: coord2);
        map.addConnection(rail2.startingConnection);
        map.addConnection(rail2.endingConnection);
        expect(map[coord2]?.length, 2);

        expect(rail1.startingConnection.activeConnection, null);
        expect(
          rail1.endingConnection.activeConnection,
          rail2.startingConnection,
        );
        expect(
          rail2.startingConnection.activeConnection,
          rail1.endingConnection,
        );
        expect(rail2.endingConnection.activeConnection, null);
      });

      test("- Bend2x2", () {
        final rail1 = Bend2x2(coord: CellCoord.zero);
        expect(rail1.startingConnection.coord, CellCoord.zero);
        expect(rail1.endingConnection.coord, const CellCoord(1, -1));

        final ConnectionMap map = {};
        map.addConnection(rail1.startingConnection);
        expect(map[CellCoord.zero], [rail1.startingConnection]);
        map.addConnection(rail1.endingConnection);
        expect(map[const CellCoord(1, -1)], [rail1.endingConnection]);

        final rail2 = Bend2x2(coord: const CellCoord(2, -3), angle: pi);
        map.addConnection(rail2.startingConnection);
        map.addConnection(rail2.endingConnection);
        expect(map[const CellCoord(2, -3)]?.length, 1);
        expect(map[const CellCoord(1, -2)]?.length, 1);

        expect(rail1.startingConnection.activeConnection, null);
        expect(
          rail1.endingConnection.activeConnection,
          rail2.endingConnection,
        );
        expect(
          rail2.endingConnection.activeConnection,
          rail1.endingConnection,
        );
        expect(rail2.startingConnection.activeConnection, null);
      });

      test("- Y Switch", () {
        final ConnectionMap map = {};

        // Pointing down
        final stem = Straight1x1(coord: CellCoord.zero, angle: pi / 2);
        map.addConnection(stem.startingConnection);
        map.addConnection(stem.endingConnection);

        // Pointing down and to the left
        final right = Bend2x2(coord: const CellCoord(1, -2), angle: -pi);
        map.addConnection(right.startingConnection);
        map.addConnection(right.endingConnection);
        expect(
            right.endingConnection.activeConnection, stem.startingConnection);
        expect(
            stem.startingConnection.activeConnection, right.endingConnection);

        // Pointing up and to the left
        final left = Bend2x2(coord: const CellCoord(0, -1), angle: -pi / 2);
        map.addConnection(left.startingConnection);
        map.addConnection(left.endingConnection);
        expect(
            left.startingConnection.activeConnection, stem.startingConnection);
        // Left should have priority by default
        // (Arbitrarily, < angle <=> > priority)
        expect(stem.startingConnection.connections, [
          left.startingConnection,
          right.endingConnection,
        ]);
        expect(
            stem.startingConnection.activeConnection, left.startingConnection);
      });
    });
  });
}
