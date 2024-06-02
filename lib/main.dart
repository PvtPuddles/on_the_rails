import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:on_the_rails/ui/overlays.dart';

import 'app.dart';

void main() {
  runApp(MaterialApp(
    home: GameWidget<OnTheRails>.controlled(
      gameFactory: OnTheRails.new,
      overlayBuilderMap: gameOverlays,
    ),
  ));
}
