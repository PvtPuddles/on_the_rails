import 'package:flame/game.dart';
import 'package:flutter/material.dart';

final frostColor = Colors.brown.shade400;

abstract class MenuManager<T> extends ChangeNotifier {
  MenuManager(this.game);

  final FlameGame game;

  String get overlayName;

  @mustCallSuper
  void add(T element) {
    game.overlays.add(overlayName);
    notifyListeners();
  }

  @mustCallSuper
  void dismiss() {
    game.overlays.remove(overlayName);
  }

  Widget buildMenu(BuildContext context);
}

class Menu<Manager extends MenuManager> extends StatelessWidget {
  const Menu({
    super.key,
    required this.manager,
    this.positionBuilder = _center,
  });

  final MenuManager manager;

  final Positioned Function(BuildContext context, Widget child) positionBuilder;

  static Positioned _center(BuildContext context, Widget child) =>
      Positioned(child: child);

  @override
  Widget build(BuildContext context) {
    final menu = GestureDetector(
      onTap: () {},
      child: ListenableBuilder(
          listenable: manager,
          builder: (context, child) {
            return manager.buildMenu(context);
          }),
    );

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onTap: manager.dismiss,
        child: Stack(
          alignment: Alignment.center,
          children: [positionBuilder(context, menu)],
        ),
      ),
    );
  }
}
