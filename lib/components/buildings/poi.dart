import 'package:flame/components.dart';
import 'package:on_the_rails/app.dart';
import 'package:on_the_rails/components/rails/rail.dart';
import 'package:on_the_rails/world/world.dart';

/// A point of interest (POI) on the map.
///
/// Since this is a train game, POIs should generally be accessible by [rails].
/// As such, agents can look up a POI by associated rails in the [PoiMap].
mixin Poi on PositionComponent, HasGameRef {
  String get name;

  RailMap get railMap => (game as OnTheRails).world.railMap;

  List<Rail> get rails;
}

class PoiMap extends Component with Notifier {
  Map<Rail?, List<Poi>> map = {};

  List<Poi> operator [](Rail? rail) {
    return [...?map[rail]];
  }

  @override
  Future<void> add(covariant Poi component) async {
    assert(parent != null);
    await super.add(component);

    final rails = component.rails;
    if (rails.isEmpty) {
      map.register(null, component);
    } else {
      for (final rail in component.rails) {
        map.register(rail, component);
      }
    }
    notifyListeners();
  }

  void recalculate() {
    final pois = map.values.expand((pois) => pois).toSet();
    map = {};
    for (final poi in pois) {
      add(poi);
    }
  }
}
