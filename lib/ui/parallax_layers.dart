import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';

/// Lightweight parallax made of moving semi-transparent bands.
/// No external images required; renders behind blocks, above gradient.
class ParallaxLayers extends Component with HasGameReference<FlameGame> {
  @override
  int priority = -95;

  double _t = 0; // time accumulator

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    final s = game.size;
    // Three layers moving at different speeds
    _drawBand(canvas, s, speed: 8, yRatio: 0.78, height: 36, color: const Color(0x14FFFFFF));
    _drawBand(canvas, s, speed: 16, yRatio: 0.62, height: 28, color: const Color(0x10FFFFFF));
    _drawBand(canvas, s, speed: 28, yRatio: 0.48, height: 22, color: const Color(0x0EFFFFFF));
  }

  void _drawBand(Canvas canvas, Vector2 s, {required double speed, required double yRatio, required double height, required Color color}) {
    final paint = Paint()..color = color;
    final y = s.y * yRatio + math.sin(_t * (speed * 0.25)) * 6;
    // Repeat tiles across width for a subtle movement
    final w = s.x / 3;
    final offset = (_t * speed) % w;
    for (double x = -offset - w; x < s.x + w; x += w) {
      final rect = Rect.fromLTWH(x, y, w, height);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), paint);
    }
  }
}
