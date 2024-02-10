import 'package:flame/components.dart';
import 'package:on_the_rails/rails/rail.dart';

const rails = [
  "bend2x2",
];

class Bend2x2 extends Rail {
  Bend2x2({required super.position})
      : super(
          name: rails[0],
          shape: [
            Vector2(0, 0),
            Vector2(0, -1),
            Vector2(-1, -1),
          ],
        );
}
