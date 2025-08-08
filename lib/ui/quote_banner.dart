import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';

class QuoteBanner extends TextComponent {
  QuoteBanner({required String text, required Vector2 position})
      : _t = 0,
        super(text: text, position: position, anchor: Anchor.bottomCenter) {
    textRenderer = TextPaint(
      style: const TextStyle(
        color: Color(0xFFFFFFFF),
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  double _t;
  static const double life = 2.8; // seconds

  void restartWith(String newText) {
    text = newText;
    _t = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    // gentle rise and fade out
    position.add(Vector2(0, -8 * dt));
    final a = (1 - (_t / life)).clamp(0.0, 1.0);
    textRenderer = TextPaint(
      style: TextStyle(
        color: const Color(0xFFFFFFFF).withValues(alpha: a * 0.9),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
    if (_t >= life) removeFromParent();
  }
}
