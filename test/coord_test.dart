import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_the_rails/coord.dart';
import 'package:on_the_rails/world.dart';

void main() {
  group("Shape Test", () {
    test("1x1", () {
      const pos = CellCoord(1, 1);
      const shape = CellShape([pos]);

      expect(shape.bounds, (pos, pos));

      const shape2 = CellShape([CellCoord.zero]);
      expect(shape2.bounds, (CellCoord.zero, CellCoord.zero));
      expect(shape2.anchor, const Anchor(.5, .5));
    });

    test("1x2", () {
      const shape = CellShape([CellCoord(0, 0), CellCoord(1, 0)]);

      expect(shape.bounds, const (CellCoord(0, 0), CellCoord(1, 0)));
      expect(shape.origin, Vector2(.5, .5));
    });

    test("2x2", () {
      const shape = CellShape([
        ...[CellCoord(0, 0), CellCoord(1, 0)],
        ...[CellCoord(1, 1), CellCoord(1, 1)],
      ]);

      expect(shape.bounds, (CellCoord.zero, const CellCoord(1, 1)));
      expect(shape.anchor, const Anchor(.25, .25));
    });

    test("Bend 2x2", () {
      const shape = CellShape([
        ...[CellCoord(0, 0) /*CellCoord(1, 0)*/],
        ...[/*CellCoord(1, 1),*/ CellCoord(1, 1)],
      ]);

      expect(shape.bounds, (CellCoord.zero, const CellCoord(1, 1)));
      expect(shape.anchor, const Anchor(.25, .25));

      const shape2 = CellShape([
        ...[CellCoord(-1, -1), CellCoord(0, -1)],
        ...[CellCoord(-1, 0), CellCoord(0, 0)],
      ]);

      expect(shape2.bounds, (const CellCoord(-1, -1), CellCoord.zero));
      expect(shape2.anchor, const Anchor(.75, .75));
    });
  });
}
