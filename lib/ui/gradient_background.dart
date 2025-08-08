import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';

class GradientBackground extends Component with HasGameReference<FlameGame> {
  @override
  int priority = -100; // render behind everything

  @override
  void render(Canvas canvas) {
    final s = game.size;
    final rect = Rect.fromLTWH(0, 0, s.x, s.y);
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment(0, -1),
        end: Alignment(0, 1),
        colors: [Color(0xFF10141A), Color(0xFF24313E)],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }
}
