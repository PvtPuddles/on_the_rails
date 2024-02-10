import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import 'rail.dart';

const rails = [
  "straight1x1",
];

Path path = Path()..lineTo(1, 0);

class Straight1x1 extends Rail {
  Straight1x1({
    required super.position,
    double? angle,
  })  : assert(
          angle == null || angle % (pi / 2) == 0,
        ),
        super(
          name: rails[0],
          shape: [
            Vector2(0, 0),
          ],
        );
}
