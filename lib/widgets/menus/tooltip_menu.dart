import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Viewport;
import 'package:frosted_glass/frosted_glass.dart';

enum TooltipMode {
  persistent,
  fleeting,
  none,
}

class TooltipManager extends ChangeNotifier {
  TooltipManager._();

  static final instance = TooltipManager._();

  PositionComponent? _target;

  PositionComponent? get target => _target;

  set target(PositionComponent? value) {
    _target = value;
    if (value == null) mode = TooltipMode.none;
    notifyListeners();
  }

  TooltipMode? _mode;

  TooltipMode? get mode => _mode;

  set mode(TooltipMode? value) {
    _mode = value;
    if (value == TooltipMode.none) _target = null;
    if (target != null) {
      notifyListeners();
    }
  }

  void showTooltip(PositionComponent target,
      {TooltipMode mode = TooltipMode.fleeting}) {
    if (this.target != target) {
      this.target = target;
      this.mode = mode;
    } else if (this.mode != mode) {
      this.mode = mode;
    }
  }

  void hideTooltip(PositionComponent target) {
    if (this.target != target) {
      return;
    }
    this.target = null;
    mode = TooltipMode.none;
  }
}

class TooltipOverlay extends StatefulWidget {
  const TooltipOverlay({
    super.key,
    required this.camera,
  });

  final CameraComponent camera;

  @override
  State<TooltipOverlay> createState() => _TooltipOverlayState();
}

class _TooltipOverlayState extends State<TooltipOverlay> {
  static const floatHeight = 16;

  @override
  Widget build(BuildContext context) {
    final manager = TooltipManager.instance;
    return ListenableBuilder(
        listenable: manager,
        builder: (context, _) {
          final target = manager.target;
          if (target == null) return const SizedBox();

          return AnimatedBuilder(
            animation: target.position,
            builder: (context, child) {
              child!;

              final offset = _offsetFor(target);

              return Stack(alignment: Alignment.center, children: [
                Positioned(
                  bottom: offset.dy,
                  child: Transform.translate(
                    offset: Offset(offset.dx, 0),
                    child: child,
                  ),
                ),
              ]);
            },
            child: FrostedGlass(
              frostColor: Colors.brown.shade400,
              frostIntensity: .75,
              margin: EdgeInsets.zero,
              child: Builder(builder: (context) {
                return Center(
                    child: Text(
                  "Tooltip menu",
                  style: Theme.of(context).textTheme.titleLarge,
                ));
              }),
            ),
          );
        });
  }

  static double _topOf(PositionComponent positioned) {
    // Tooltip float height caused by the width of the car
    final heightW = positioned.height / 2 * cos(positioned.angle).abs();
    // Tooltip float height caused by the length of the car
    final heightL = positioned.width / 2 * sin(positioned.angle).abs();
    return heightW + heightL;
  }

  /// Returns an screen-space offset from the bottom-center of the camera to the
  /// center of the component, plus [floatHeight]
  Offset _offsetFor(PositionComponent component) {
    Offset center = Offset(
        component.position.x - widget.camera.visibleWorldRect.center.dx,
        widget.camera.visibleWorldRect.bottom - component.position.y);
    return center + Offset(0, _topOf(component) + floatHeight);
  }
}
