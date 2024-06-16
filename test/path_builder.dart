import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_the_rails/agents/path_builders/path_builder.dart';
import 'package:on_the_rails/components/rails/shapes.dart';
import 'package:on_the_rails/world/world.dart';

int _degrees(double radians) {
  return (radians / pi * 180).round();
}

void main() {
  const topLeft = CellCoord(-5, 5),
      top = CellCoord(0, 5),
      topRight = CellCoord(5, 5);
  const left = CellCoord(-5, 0),
      center = CellCoord.zero,
      right = CellCoord(5, 0);
  const bottomLeft = CellCoord(-5, -5),
      bottom = CellCoord(0, -5),
      bottomRight = CellCoord(5, -5);

  group("Straights", () {
    test("Right", () {
      final line = PathBuilder.lineFrom(center, to: right);
      expect(RailMap.drawRails(line), "▷ ▷ ▷ ▷ ");
      expect(
        line.map((e) => e.coord),
        const [
          CellCoord(1, 0),
          CellCoord(2, 0),
          CellCoord(3, 0),
          CellCoord(4, 0)
        ],
      );
    });
    test("Left", () {
      final line = PathBuilder.lineFrom(right, to: center);
      expect(RailMap.drawRails(line), "◁ ◁ ◁ ◁ ");
      expect(
        line.map((e) => e.coord),
        const [
          CellCoord(4, 0),
          CellCoord(3, 0),
          CellCoord(2, 0),
          CellCoord(1, 0)
        ],
      );
    });
    test("Up", () {
      final line = PathBuilder.lineFrom(center, to: top);
      expect(RailMap.drawRails(line), '△ \n△ \n△ \n△ ');
      expect(
        line.map((e) => e.coord),
        const [
          CellCoord(0, 1),
          CellCoord(0, 2),
          CellCoord(0, 3),
          CellCoord(0, 4)
        ],
      );
    });
    test("Down", () {
      final line = PathBuilder.lineFrom(top, to: center);
      expect(RailMap.drawRails(line), '▽ \n▽ \n▽ \n▽ ');
      expect(
        line.map((e) => e.coord),
        const [
          CellCoord(0, 4),
          CellCoord(0, 3),
          CellCoord(0, 2),
          CellCoord(0, 1)
        ],
      );
    });
  });

  group("Curves", () {
    group("angleBetween()", () {
      test("Right angle", () {
        expect(_degrees(PathBuilder.angleBetween(0, pi / 2)), 90);
        expect(_degrees(PathBuilder.angleBetween(pi / 2, 0)), -90);

        expect(_degrees(PathBuilder.angleBetween(pi / 2, pi)), 90);
        expect(_degrees(PathBuilder.angleBetween(pi, pi / 2)), -90);

        expect(_degrees(PathBuilder.angleBetween(-pi / 4, pi / 4)), 90);
        expect(_degrees(PathBuilder.angleBetween(pi / 4, -pi / 4)), -90);
      });
      test("Acute angle", () {
        expect(_degrees(PathBuilder.angleBetween(0, pi / 4)), 45);
        expect(_degrees(PathBuilder.angleBetween(pi / 4, 0)), -45);

        expect(_degrees(PathBuilder.angleBetween(pi, pi + pi / 4)), 45);
        expect(_degrees(PathBuilder.angleBetween(pi + pi / 4, pi)), -45);
      });
      test("Obtuse angle", () {
        expect(_degrees(PathBuilder.angleBetween(0, 3 * pi / 4)), 135);
        expect(_degrees(PathBuilder.angleBetween(3 * pi / 4, 0)), -135);
      });
    });

    group("Clockwise", () {
      test("CC Up", () {
        final cc = PathBuilder.bendFrom(bottom, -pi, to: left, toAngle: pi / 2);
        expect(
          "\n${RailMap.drawRails(cc)}",
          "\n"
              /*      - 5 4 3 2 1  */
              /* -1 */ "△         \n"
              /* -2 */ "△         \n"
              /* -3 */ "△         \n"
              /* -4 */ "▢         \n"
              /* -5 */ "  ◁ ◁ ◁ ◁ ",
        );
      });

      test("CC Right", () {
        final cc = PathBuilder.bendFrom(left, pi / 2, to: top, toAngle: 0);
        expect(
          "\n${RailMap.drawRails(cc)}",
          "\n"
              /*     - 5 4 3 2 1  */
              /* 5 */ "  ▢ ▷ ▷ ▷ \n"
              /* 4 */ "△         \n"
              /* 3 */ "△         \n"
              /* 2 */ "△         \n"
              /* 1 */ "△         ",
        );
      });

      test("CC Down", () {
        final curveDown =
            PathBuilder.bendFrom(center, 0, to: bottomRight, toAngle: -pi / 2);
        expect(
          "\n${RailMap.drawRails(curveDown)}",
          "\n"
              // Curve is exclusive of ends; Should not include (0, 0) or (5, -5)
              /*       1 2 3 4 5  */
              /* 0 */ "▷ ▷ ▷ ▷   \n"
              /* 1 */ "        ▢ \n"
              /* 2 */ "        ▽ \n"
              /* 3 */ "        ▽ \n"
              /* 4 */ "        ▽ ",
        );
      });

      test("CC Left", () {
        final curveLeft =
            PathBuilder.bendFrom(right, -pi / 2, to: bottom, toAngle: -pi);
        expect(
          "\n${RailMap.drawRails(curveLeft)}",
          "\n"
              /*        1 2 3 4 5  */
              /*  0 */ "        ▽ \n"
              /* -1 */ "        ▽ \n"
              /* -2 */ "        ▽ \n"
              /* -3 */ "        ▽ \n"
              /* -4 */ "◁ ◁ ◁ ▢   ",
        );
      });
    });

    group("Counter clockwise", () {
      test("CCW Up", () {
        final ccw =
            PathBuilder.bendFrom(center, 0, to: topRight, toAngle: pi / 2);
        expect(
          "\n${RailMap.drawRails(ccw)}",
          "\n"
              // Curve is exclusive of ends; Should not include (0, 0) or (5, 5)
              /*       1 2 3 4 5  */
              /* 4 */ "        △ \n"
              /* 3 */ "        △ \n"
              /* 2 */ "        △ \n"
              /* 1 */ "        ▽ \n"
              /* 0 */ "▷ ▷ ▷ ▢   ",
        );
      });

      test("CCW Left", () {
        final ccw =
            PathBuilder.bendFrom(center, pi / 2, to: topLeft, toAngle: pi);
        expect(
          "\n${RailMap.drawRails(ccw)}",
          "\n"
              // Curve is exclusive of ends; Should not include (0, 0) or (5, 5)
              /*       1 2 3 4 5  */
              /* 4 */ "◁ ◁ ◁ ▷   \n"
              /* 3 */ "        ▢ \n"
              /* 2 */ "        △ \n"
              /* 1 */ "        △ \n"
              /* 0 */ "        △ ",
        );
      });

      test("CCW Down", () {
        final ccw =
            PathBuilder.bendFrom(center, -pi, to: bottomLeft, toAngle: -pi / 2);
        expect(
          "\n${RailMap.drawRails(ccw)}",
          "\n"
              // Curve is exclusive of ends; Should not include (0, 0) or (5, 5)
              /*       1 2 3 4 5  */
              /* 4 */ "  ▢ ◁ ◁ ◁ \n"
              /* 3 */ "△         \n"
              /* 2 */ "▽         \n"
              /* 1 */ "▽         \n"
              /* 0 */ "▽         ",
        );
      });

      test("CCW Right", () {
        final ccw =
            PathBuilder.bendFrom(center, -pi / 2, to: bottomRight, toAngle: 0);
        expect(
          "\n${RailMap.drawRails(ccw)}",
          "\n"
              // Curve is exclusive of ends; Should not include (0, 0) or (5, 5)
              /*       1 2 3 4 5  */
              /* 4 */ "▽         \n"
              /* 3 */ "▽         \n"
              /* 2 */ "▽         \n"
              /* 1 */ "▢         \n"
              /* 0 */ "  ◁ ▷ ▷ ▷ ",
        );
      });
    });
  });

  group("Path Builder", () {
    group("Straight Rails", () {
      test("Right", () {
        final start = Straight1(coord: center);
        final end = Straight1(coord: right);
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
      });
      test("Left", () {
        final start = Straight1(coord: center);
        final end = Straight1(coord: left);
        expect(
          PathBuilder.buildPathBetween(
                  start.endingConnection, end.startingConnection)
              .map((e) => e.coord),
          const [
            CellCoord(-1, 0),
            CellCoord(-2, 0),
            CellCoord(-3, 0),
            CellCoord(-4, 0)
          ],
        );
      });
      test("Up", () {
        final start = Straight1(coord: center, angle: pi / 2);
        final end = Straight1(coord: top, angle: pi / 2);
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
      });
      test("Down", () {
        final start = Straight1(coord: center, angle: pi / 2);
        final end = Straight1(coord: bottom, angle: pi / 2);
        expect(
          PathBuilder.buildPathBetween(
                  start.endingConnection, end.startingConnection)
              .map((e) => e.coord),
          const [
            CellCoord(0, -1),
            CellCoord(0, -2),
            CellCoord(0, -3),
            CellCoord(0, -4)
          ],
        );
      });
    });

    group("Curved Rails", () {
      group("Clockwise", () {
        test("CC Up", () {
          final start = Straight1(coord: bottom, angle: -pi);
          final end = Straight1(coord: left, angle: pi / 2);
          final path = PathBuilder.buildPathBetween(
              start.endingConnection, end.startingConnection);
          expect(
            path.map((e) => e.coord),
            const [
              CellCoord(-1, -5),
              CellCoord(-2, -5),
              CellCoord(-3, -5),
              CellCoord(-4, -5), // Curve
              CellCoord(-5, -3),
              CellCoord(-5, -2),
              CellCoord(-5, -1),
            ],
          );
        });

        test("CC Right", () {
          final start = Straight1(coord: left, angle: pi / 2);
          final end = Straight1(coord: top, angle: 0);
          final path = PathBuilder.buildPathBetween(
              start.endingConnection, end.startingConnection);
          expect(
            path.map((e) => e.coord),
            const [
              CellCoord(-5, 1),
              CellCoord(-5, 2),
              CellCoord(-5, 3),
              CellCoord(-5, 4), // Curve
              CellCoord(-3, 5),
              CellCoord(-2, 5),
              CellCoord(-1, 5),
            ],
          );
        });

        test("CC Down", () {
          final start = Straight1(coord: top, angle: 0);
          final end = Straight1(coord: right, angle: -pi / 2);
          final path = PathBuilder.buildPathBetween(
              start.endingConnection, end.startingConnection);
          expect(
            path.map((e) => e.coord),
            const [
              CellCoord(1, 5),
              CellCoord(2, 5),
              CellCoord(3, 5),
              CellCoord(4, 5), // Curve
              CellCoord(5, 3),
              CellCoord(5, 2),
              CellCoord(5, 1),
            ],
          );
        });

        test("CC Left", () {
          final start = Straight1(coord: right, angle: -pi / 2);
          final end = Straight1(coord: bottom, angle: -pi);
          final path = PathBuilder.buildPathBetween(
              start.endingConnection, end.startingConnection);
          expect(
            path.map((e) => e.coord),
            const [
              CellCoord(5, -1),
              CellCoord(5, -2),
              CellCoord(5, -3),
              CellCoord(5, -4), // Curve
              CellCoord(3, -5),
              CellCoord(2, -5),
              CellCoord(1, -5),
            ],
          );
        });
      });

      group("Counter Clockwise", () {
        test("CCW Up", () {
          final start = Straight1(coord: bottom, angle: pi);
          final end = Straight1(coord: right, angle: pi / 2);
          final path = PathBuilder.buildPathBetween(
              start.endingConnection, end.startingConnection);
          expect(
            path.map((e) => e.coord),
            const [
              CellCoord(1, -5),
              CellCoord(2, -5),
              CellCoord(3, -5),
              CellCoord(4, -5), // Curve
              CellCoord(5, -3),
              CellCoord(5, -2),
              CellCoord(5, -1),
            ],
          );
        });

        test("CCW Left", () {
          final start = Straight1(coord: right, angle: pi / 2);
          final end = Straight1(coord: top, angle: -pi);
          final path = PathBuilder.buildPathBetween(
              start.endingConnection, end.startingConnection);
          expect(
            path.map((e) => e.coord),
            const [
              CellCoord(5, 1),
              CellCoord(5, 2),
              CellCoord(5, 3),
              CellCoord(4, 5), // Curve
              CellCoord(3, 5),
              CellCoord(2, 5),
              CellCoord(1, 5),
            ],
          );
        });

        test("CCW Down", () {
          final start = Straight1(coord: top, angle: 0);
          final end = Straight1(coord: left, angle: -pi / 2);
          final path = PathBuilder.buildPathBetween(
              start.endingConnection, end.startingConnection);
          expect(
            path.map((e) => e.coord),
            const [
              CellCoord(-1, 5),
              CellCoord(-2, 5),
              CellCoord(-3, 5),
              CellCoord(-4, 5), // Curve
              CellCoord(-5, 3),
              CellCoord(-5, 2),
              CellCoord(-5, 1),
            ],
          );
        });

        test("CCW Right", () {
          final start = Straight1(coord: left, angle: -pi / 2);
          final end = Straight1(coord: bottom, angle: pi);
          final path = PathBuilder.buildPathBetween(
              start.endingConnection, end.startingConnection);
          expect(
            path.map((e) => e.coord),
            const [
              CellCoord(-5, -1),
              CellCoord(-5, -2),
              CellCoord(-5, -3),
              CellCoord(-5, -4), // Curve
              CellCoord(-3, -5),
              CellCoord(-2, -5),
              CellCoord(-1, -5),
            ],
          );
        });
      });
    });

    // group("S Bends", () {
    //   group("Clockwise", () {
    //     test("S Up", () {
    //       final start = Straight1(coord: center, angle: 0);
    //       final end = Straight1(coord: topRight, angle: 0);
    //       final path = PathBuilder.buildPathBetween(
    //           start.endingConnection, end.startingConnection);
    //
    //       expect(
    //         "\n${RailMap.drawRails(path)}",
    //         "\n"
    //             /*       1 2 3 4  */
    //             /* 4 */ "    ▢ ▷ \n"
    //             /* 3 */ "  △     \n"
    //             /* 2 */ "  △     \n"
    //             /* 1 */ "  ▽     \n"
    //             /* 0 */ "▢       ",
    //       );
    //     });
    //
    //     test("CC Right", () {
    //       final start = Straight1(coord: left, angle: pi / 2);
    //       final end = Straight1(coord: top, angle: 0);
    //       final path = PathBuilder.buildPathBetween(
    //           start.endingConnection, end.startingConnection);
    //       expect(
    //         path.map((e) => e.coord),
    //         const [
    //           CellCoord(-5, 1),
    //           CellCoord(-5, 2),
    //           CellCoord(-5, 3),
    //           CellCoord(-5, 4), // Curve
    //           CellCoord(-3, 5),
    //           CellCoord(-2, 5),
    //           CellCoord(-1, 5),
    //         ],
    //       );
    //     });
    //
    //     test("CC Down", () {
    //       final start = Straight1(coord: top, angle: 0);
    //       final end = Straight1(coord: right, angle: -pi / 2);
    //       final path = PathBuilder.buildPathBetween(
    //           start.endingConnection, end.startingConnection);
    //       expect(
    //         path.map((e) => e.coord),
    //         const [
    //           CellCoord(1, 5),
    //           CellCoord(2, 5),
    //           CellCoord(3, 5),
    //           CellCoord(4, 5), // Curve
    //           CellCoord(5, 3),
    //           CellCoord(5, 2),
    //           CellCoord(5, 1),
    //         ],
    //       );
    //     });
    //
    //     test("CC Left", () {
    //       final start = Straight1(coord: right, angle: -pi / 2);
    //       final end = Straight1(coord: bottom, angle: -pi);
    //       final path = PathBuilder.buildPathBetween(
    //           start.endingConnection, end.startingConnection);
    //       expect(
    //         path.map((e) => e.coord),
    //         const [
    //           CellCoord(5, -1),
    //           CellCoord(5, -2),
    //           CellCoord(5, -3),
    //           CellCoord(5, -4), // Curve
    //           CellCoord(3, -5),
    //           CellCoord(2, -5),
    //           CellCoord(1, -5),
    //         ],
    //       );
    //     });
    //   });
    // });
  });

  group("A*", () {
    test("Path of", () async {
      // final map = RailMap();
      // const delta = CellCoord(1, 0);
      // final a = Straight1(coord: center);
      // final b = Straight1(coord: center + delta, angle: pi);
      // final c = Straight1(coord: center + (delta * 2));
      // await map.addAllRails([a, b, c]);
      // expect(c.endingConnection.getPathTo(a), [c, b, a]);
    });

    group("Straight", () {
      test("Right", () async {
        final start = Straight1(coord: center, angle: 0);
        final end = Straight1(coord: right, angle: 0);

        final path = await (AStarBuilder(
                from: start.endingConnection, to: end.startingConnection)
            .buildPath());
        expect(RailMap.drawRails(path), "▷ ▷ ▷ ▷ ");
      });

      test("Up", () async {
        final start = Straight1(coord: center, angle: pi / 2);
        final end = Straight1(coord: top, angle: pi / 2);

        final path = await (AStarBuilder(
                from: start.endingConnection, to: end.startingConnection)
            .buildPath());
        expect(RailMap.drawRails(path), '△ \n△ \n△ \n△ ');
      });
    });

    // Not happy with how the algorithm handles diagonal lines
    group("Curves", skip: "Improve Diagonals", () {
      group("Clockwise", () {
        test("CC Up", () async {
          final start = Straight1(coord: bottom, angle: -pi);
          final end = Straight1(coord: left, angle: pi / 2);
          final path = await AStarBuilder(
                  from: start.endingConnection, to: end.startingConnection)
              .buildPath();
          expect(
            path.map((e) => e.coord),
            const [
              CellCoord(-1, -5),
              CellCoord(-2, -5),
              CellCoord(-3, -5),
              CellCoord(-4, -5), // Curve
              CellCoord(-5, -3),
              CellCoord(-5, -2),
              CellCoord(-5, -1),
            ],
          );
        });

        test("CC Right", () async {
          final start = Straight1(coord: left, angle: pi / 2);
          final end = Straight1(coord: top, angle: 0);
          final path = await AStarBuilder(
                  from: start.endingConnection, to: end.startingConnection)
              .buildPath();
          expect(
            path.map((e) => e.coord),
            const [
              CellCoord(-5, 1),
              CellCoord(-5, 2),
              CellCoord(-5, 3),
              CellCoord(-5, 4), // Curve
              CellCoord(-3, 5),
              CellCoord(-2, 5),
              CellCoord(-1, 5),
            ],
          );
        });

        test("CC Down", () async {
          final start = Straight1(coord: top, angle: 0);
          final end = Straight1(coord: right, angle: -pi / 2);
          final path = await AStarBuilder(
                  from: start.endingConnection, to: end.startingConnection)
              .buildPath();
          expect(
            path.map((e) => e.coord),
            const [
              CellCoord(1, 5),
              CellCoord(2, 5),
              CellCoord(3, 5),
              CellCoord(4, 5), // Curve
              CellCoord(5, 3),
              CellCoord(5, 2),
              CellCoord(5, 1),
            ],
          );
        });

        test("CC Left", () async {
          final start = Straight1(coord: right, angle: -pi / 2);
          final end = Straight1(coord: bottom, angle: -pi);
          final path = await AStarBuilder(
                  from: start.endingConnection, to: end.startingConnection)
              .buildPath();
          expect(
            path.map((e) => e.coord),
            const [
              CellCoord(5, -1),
              CellCoord(5, -2),
              CellCoord(5, -3),
              CellCoord(5, -4), // Curve
              CellCoord(3, -5),
              CellCoord(2, -5),
              CellCoord(1, -5),
            ],
          );
        });
      });

      group("Counter Clockwise", () {
        test("CCW Up", () async {
          final start = Straight1(coord: bottom, angle: pi);
          final end = Straight1(coord: right, angle: pi / 2);
          final path = await AStarBuilder(
                  from: start.endingConnection, to: end.startingConnection)
              .buildPath();
          expect(
            path.map((e) => e.coord),
            const [
              CellCoord(1, -5),
              CellCoord(2, -5),
              CellCoord(3, -5),
              CellCoord(4, -5), // Curve
              CellCoord(5, -3),
              CellCoord(5, -2),
              CellCoord(5, -1),
            ],
          );
        });

        test("CCW Left", () async {
          final start = Straight1(coord: right, angle: pi / 2);
          final end = Straight1(coord: top, angle: -pi);
          final path = await AStarBuilder(
                  from: start.endingConnection, to: end.startingConnection)
              .buildPath();
          expect(
            path.map((e) => e.coord),
            const [
              CellCoord(5, 1),
              CellCoord(5, 2),
              CellCoord(5, 3),
              CellCoord(4, 5), // Curve
              CellCoord(3, 5),
              CellCoord(2, 5),
              CellCoord(1, 5),
            ],
          );
        });

        test("CCW Down", () async {
          final start = Straight1(coord: top, angle: 0);
          final end = Straight1(coord: left, angle: -pi / 2);
          final path = await AStarBuilder(
                  from: start.endingConnection, to: end.startingConnection)
              .buildPath();
          expect(
            path.map((e) => e.coord),
            const [
              CellCoord(-1, 5),
              CellCoord(-2, 5),
              CellCoord(-3, 5),
              CellCoord(-4, 5), // Curve
              CellCoord(-5, 3),
              CellCoord(-5, 2),
              CellCoord(-5, 1),
            ],
          );
        });

        test("CCW Right", () async {
          final start = Straight1(coord: left, angle: -pi / 2);
          final end = Straight1(coord: bottom, angle: pi);
          final path = await AStarBuilder(
                  from: start.endingConnection, to: end.startingConnection)
              .buildPath();
          expect(
            path.map((e) => e.coord),
            const [
              CellCoord(-5, -1),
              CellCoord(-5, -2),
              CellCoord(-5, -3),
              CellCoord(-5, -4), // Curve
              CellCoord(-3, -5),
              CellCoord(-2, -5),
              CellCoord(-1, -5),
            ],
          );
        });
      });
    });

    test("U Turn", () async {
      final start = Straight1(coord: bottom, angle: 0);
      final end = Straight1(coord: center, angle: pi);
      final cw = await AStarBuilder(
              from: end.startingConnection, to: start.endingConnection)
          .buildPath();
      final ccw = await AStarBuilder(
              from: start.endingConnection, to: end.startingConnection)
          .buildPath();
      expect(
        RailMap.drawRails(cw),
        "▷   \n"
        "  ▢ \n"
        "  ▽ \n"
        "  ▽ \n"
        "  ▽ \n"
        "▢   ",
      );
      expect(
        RailMap.drawRails(ccw),
        "▷   \n"
        "  ▢ \n"
        "  △ \n"
        "  △ \n"
        "  ▽ \n"
        "▢   ",
      );
    });
  });
}
