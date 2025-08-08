import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';

class FloatingText extends TextComponent {
  FloatingText({required super.text, required Vector2 position})
      : _t = 0,
        super(
          anchor: Anchor.center,
          position: position,
        ) {
    textRenderer = TextPaint(
      style: const TextStyle(
        color: Color(0xFFFFFFFF),
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  double _t;
  static const double life = 0.9;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    // move up and fade
    position.add(Vector2(0, -24 * dt));
    final a = (1 - (_t / life)).clamp(0.0, 1.0);
    textRenderer = TextPaint(
      style: TextStyle(
        color: const Color(0xFFFFFFFF).withValues(alpha: a),
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
    );
    if (_t >= life) {
      removeFromParent();
    }
  }
}
