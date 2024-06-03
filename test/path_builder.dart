import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_the_rails/agents/path_builder.dart';
import 'package:on_the_rails/components/rails/shapes.dart';
import 'package:on_the_rails/world/world.dart';

void main() {
  group("LineTo", () {
    test("Straight across", () {
      final start = Straight1(coord: CellCoord.zero);
      final end = Straight1(coord: const CellCoord(5, 0));

      expect(
        PathBuilder.buildPathBetween(
                start.endingConnection, end.startingConnection)
            .map((e) => e.coord),
        const [
          CellCoord(1, 0),
          CellCoord(2, 0),
          CellCoord(3, 0),
          CellCoord(4, 0)
        ],
      );
      expect(
        PathBuilder.buildPathBetween(
                end.startingConnection, start.endingConnection)
            .map((e) => e.coord),
        const [
          CellCoord(4, 0),
          CellCoord(3, 0),
          CellCoord(2, 0),
          CellCoord(1, 0)
        ],
      );
    });

    test("Straight vertical", () {
      final start = Straight1(coord: CellCoord.zero, angle: pi / 2);
      final end = Straight1(coord: const CellCoord(0, 5), angle: pi / 2);

      expect(
        PathBuilder.buildPathBetween(
                start.endingConnection, end.startingConnection)
            .map((e) => e.coord),
        const [
          CellCoord(0, 1),
          CellCoord(0, 2),
          CellCoord(0, 3),
          CellCoord(0, 4)
        ],
      );
      expect(
        PathBuilder.buildPathBetween(
                end.startingConnection, start.endingConnection)
            .map((e) => e.coord),
        const [
          CellCoord(0, 4),
          CellCoord(0, 3),
          CellCoord(0, 2),
          CellCoord(0, 1)
        ],
      );
    });
  });
}
