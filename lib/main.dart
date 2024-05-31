import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:on_the_rails/rails/rail.dart';

import 'app.dart';

void main() {
  runApp(const MaterialApp(
    home: GameWidget<OnTheRails>.controlled(
      gameFactory: OnTheRails.new,
    ),
  ));
}
