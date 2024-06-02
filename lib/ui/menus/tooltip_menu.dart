import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Viewport;
import 'package:frosted_glass/frosted_glass.dart';

enum TooltipMode {
  persistent,
  fleeting,
  none,
}

mixin HasTooltip on PositionComponent {
  Widget buildTooltip(BuildContext context, TooltipMode mode);
}

class TooltipManager extends ChangeNotifier {
  TooltipManager._();

  static final instance = TooltipManager._();

  HasTooltip? _target;

  HasTooltip? get target => _target;

  set target(HasTooltip? value) {
    _target = value;
    if (value == null) _mode = TooltipMode.none;
    notifyListeners();
  }

  TooltipMode _mode = TooltipMode.none;

  TooltipMode get mode => _mode;

  set mode(TooltipMode value) {
    if (value == TooltipMode.none) {
      target = null;
      return;
    }
    _mode = value;
    notifyListeners();
  }

  void showTooltip(HasTooltip target,
      {TooltipMode mode = TooltipMode.fleeting}) {
    if (this.target != target) {
      this.target = target;
      this.mode = mode;
    } else if (this.mode != mode) {
      this.mode = mode;
    }
  }

  void hideTooltip(HasTooltip target) {
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
          if (target == null || manager.mode == TooltipMode.none) {
            return const SizedBox();
          }

          return AnimatedBuilder(
            animation: target.position,
            builder: (context, child) {
              child!;
              // Bottom-center of the tooltip
              final offset = _offsetFor(target);
              // Highest possible elevation for the tooltip

              late double maxHeight;
              if (manager.mode == TooltipMode.persistent) {
                const viewPadding = 16;
                maxHeight = (MediaQuery.of(context).size.height - offset.dy) -
                    viewPadding;
                // Pad the top by a little extra, so the tooltip doesn't resize
                // as the target rotates. (Prevents losing scroll position)
                maxHeight -= (_maxHeightOf(target) - _topOf(target));
              } else {
                maxHeight = double.maxFinite;
              }

              final onTap = manager.mode == TooltipMode.persistent
                  ? () {
                      manager.mode = TooltipMode.none;
                    }
                  : null;

              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: onTap,
                child: Stack(alignment: Alignment.center, children: [
                  Positioned(
                    bottom: offset.dy,
                    child: Transform.translate(
                      offset: Offset(offset.dx, 0),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: 0,
                          maxHeight: max(maxHeight, 0),
                        ),
                        child: GestureDetector(
                          // Block tap events within tooltip from dismissing the
                          // tooltip.
                          onTap: () {},
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ]),
              );
            },
            child: FrostedGlass(
              frostColor: Colors.brown.shade400,
              frostIntensity: .75,
              margin: EdgeInsets.zero,
              child: Builder(builder: (context) {
                return target.buildTooltip(context, manager.mode);
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

  double _maxHeightOf(PositionComponent component) {
    return max(component.height / 2, component.width / 2);
  }
}
