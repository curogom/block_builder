import 'dart:ui';

import 'package:flame/components.dart';

class Fragment extends RectangleComponent {
  Fragment({
    required super.position,
    required super.size,
    required Color color,
    required this.vx,
    required this.vy,
    required this.angularVelocity,
    required this.life,
  })  : _t = 0,
        super(anchor: Anchor.topLeft, paint: Paint()..color = color.withValues(alpha: 0.95));

  final double vx;
  final double vy;
  final double angularVelocity; // radians/sec
  final double life;
  double _t;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    position.x += vx * dt;
    position.y += vy * dt;
    angle += angularVelocity * dt;
    double a = 1 - (_t / life);
    if (a < 0) a = 0;
    if (a > 1) a = 1;
    paint.color = paint.color.withValues(alpha: a);
    if (_t >= life) {
      removeFromParent();
    }
  }
}
