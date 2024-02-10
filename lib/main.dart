import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'app.dart';

void main() {
  runApp(const GameWidget<OnTheRails>.controlled(
    gameFactory: OnTheRails.new,
  ));
}
