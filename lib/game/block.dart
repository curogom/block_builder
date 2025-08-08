import 'dart:math' as math;
import 'dart:ui' show Canvas, Color, Paint, Rect, RRect, Radius, PaintingStyle;

import 'package:flame/components.dart';

class StackBlock extends PositionComponent {
  StackBlock({required Vector2 position, required Vector2 size, required this.color}) {
    this.position = position;
    this.size = size;
    anchor = Anchor.topLeft;
  }

  final Color color;
  // Minimum width the block should keep (for gameplay/branding)
  double minWidth = 0;
  bool isDropping = false;
  bool frozen = false; // stop all movement once landed
  bool infiniteWidth = false; // treat as infinitely wide for overlap logic
  double horizontalSpeed = 120; // px/s
  double direction = 1; // 1: right, -1: left
  double maxX = 0; // right boundary (left boundary is 0)
  bool wrap = false; // if true, wrap horizontally instead of bouncing

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final r = _cornerRadius();
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(r));
    final fill = Paint()..color = color;
    canvas.drawRRect(rr, fill);

    // Subtle outline for better contrast against background
    final lum = color.computeLuminance();
    final outlineColor = (lum < 0.5)
        ? const Color(0x66FFFFFF)
        : const Color(0x66000000);
    final stroke = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(rr, stroke);
  }

  double _cornerRadius() {
    // Slight rounding: ~8% of the smaller edge, gently clamped
    final base = math.min(size.x, size.y) * 0.08;
    return base.clamp(2.0, 6.0);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (frozen) return;

    if (!isDropping) {
      if (wrap) {
        position.x += horizontalSpeed * direction * dt;
        if (direction >= 0 && position.x > maxX) {
          position.x = -size.x; // appear from left
        } else if (direction < 0 && position.x < -size.x) {
          position.x = maxX; // appear from right
        }
      } else {
        position.x += horizontalSpeed * direction * dt;
        if (position.x <= 0) {
          position.x = 0;
          direction = 1;
        } else if (position.x >= maxX) {
          position.x = maxX;
          direction = -1;
        }
      }
    } else {
      position.y += 1100 * dt; // drop speed slightly faster
    }
  }
}
