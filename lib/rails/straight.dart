import 'package:flame/components.dart';

import 'rail.dart';

const rails = [
  "straight1x1",
];

class Straight1x1 extends Rail {
  Straight1x1({required super.position})
      : super(
          name: rails[0],
          shape: [
            Vector2(0, 0),
          ],
        );
}
