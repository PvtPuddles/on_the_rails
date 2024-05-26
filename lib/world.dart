import 'package:flame/components.dart';
import 'package:on_the_rails/rails/rail.dart';

const double cellSize = 128;

class RailWorld extends World {
  RailWorld();

  /// A container holding all the the rails in the game.
  final railMap = RailMap();

  @override
  Future<void> onLoad() async {
    await add(railMap);
  }

  void addRail(Rail rail) {
    railMap.addRail(rail);
  }
}

extension Register<K, T> on Map<K, List<T>> {
  void register(K key, T value) {
    if (containsKey(key)) {
      this[key]!.add(value);
    } else {
      this[key] = [value];
    }
  }
}

@immutable
class CellCoord {
  static const zero = CellCoord(0, 0);

  const CellCoord(this.x, this.y);

  final int x;
  final int y;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CellCoord) return false;
    return x == other.x && y == other.y;
  }

  CellCoord operator +(CellCoord other) {
    return CellCoord(x + other.x, y + other.y);
  }

  @override
  int get hashCode => Object.hashAll([x, y]);

  Vector2 get position => toVector() * cellSize;

  Vector2 toVector() => Vector2(x.toDouble(), y.toDouble());
  Offset toOffset() => Offset(x.toDouble(), y.toDouble());

  @override
  String toString() {
    return "($x, $y)";
  }
}

extension VectorToCellCoord on Vector2 {
  CellCoord toCoord() => CellCoord(x.round(), y.round());
}

extension OffsetToCellCoord on Offset {
  CellCoord toCoord() => CellCoord(dx.round(), dy.round());
}
