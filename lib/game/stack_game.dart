import 'dart:math' as math;

import 'package:block_builder/docs/color.dart' as doc_colors;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/widgets.dart';

import '../ui/floating_text.dart';
import '../ui/gradient_background.dart';
import '../ui/parallax_layers.dart';
import '../ui/quote_banner.dart';
import '../util/contrast.dart';
import '../theme/brand_quotes.dart';
import 'block.dart' as bb;
import 'fragment.dart';

enum GamePhase { playing, paused, gameOver }

class StackGame extends FlameGame with TapCallbacks {
  static const double maxHorizontalSpeed = 1000; // raised cap
  static const double sessionSeconds = 180.0;
  double remaining = sessionSeconds;
  int score = 0;
  GamePhase phase = GamePhase.playing;

  // Camera follow target (top of the stack)
  final Vector2 stackTop = Vector2(0, 0);
  late double _initialViewY;

  // HUD bindings
  final ValueNotifier<int> timeVN = ValueNotifier(sessionSeconds.toInt());
  final ValueNotifier<int> scoreVN = ValueNotifier(0);
  final ValueNotifier<int> comboVN = ValueNotifier(0);

  // Stack state
  final List<bb.StackBlock> _stack = [];
  bb.StackBlock? _moving;
  late double _groundY;
  final Vector2 _initialBlockSize = Vector2(240, 40);
  double _speed = 220; // base horizontal speed (faster)
  int _combo = 0;
  bool _warned = false;
  final Set<String> _availableAudio = <String>{};
  final Map<String, AudioPool> _pools = <String, AudioPool>{};
  // All world components (blocks, effects) live under this root so we can
  // move the world independently of the camera when needed.
  final PositionComponent worldRoot = PositionComponent();

  @override
  Color backgroundColor() => const Color(0xFF10141A);

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topCenter;
    add(GradientBackground());
    add(ParallaxLayers());
    camera.viewfinder.position = Vector2(size.x / 2, size.y * 0.15);
    _initialViewY = camera.viewfinder.position.y;
    _groundY = size.y * 0.75;
    // World root where gameplay elements are attached
    add(worldRoot);
    // We'll control the camera manually in update() to keep
    // the top of the stack in view.
    // Preload logo assets to ensure Sprite creation doesn't fail at runtime
    try {
      await images.loadAll(const [
        'logo_imweb_white.webp',
        'logo_imweb_black.webp',
      ]);
    } catch (_) {
      // ignore; fallback to text will be used if loading fails
    }
    // Spawn base (first landed) block as foundation
    // Base foundation: visually span full screen width, logically infinite overlap
    final base = bb.StackBlock(
      position: Vector2(0, _groundY - _initialBlockSize.y),
      size: Vector2(size.x, _initialBlockSize.y),
      color: const Color(0xFFFFFFFF),
    )
      ..frozen = true
      ..infiniteWidth = true;
    worldRoot.add(base);
    _stack.add(base);
    stackTop.setValues(base.position.x, base.position.y);

    // Spawn initial moving block
    await _spawnMovingBlock();

    // Show tutorial on first load (dismiss with first tap)
    overlays.add('Tutorial');
    // Keep the first moving block centered until tutorial is dismissed
    _moving?.horizontalSpeed = 0;

    // Create audio pools to cap max concurrent players per SFX
    for (final f in const ['drop.wav', 'land.wav', 'trim.wav', 'warn.wav', 'gameover.wav']) {
      try {
        final pool = await FlameAudio.createPool(f, maxPlayers: 3);
        _pools[f] = pool;
      } catch (_) {
        // ignore if asset missing or unsupported; we'll skip playing that sound
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (phase == GamePhase.paused) return;
    if (phase != GamePhase.playing) return;
    remaining -= dt;
    if (remaining <= 0) {
      remaining = 0;
      phase = GamePhase.gameOver;
      overlays.add('Hud');
      overlays.add('GameOver');
      _play('gameover.mp3');
    }
    final secs = remaining.ceil();
    if (secs != timeVN.value) timeVN.value = secs;
    if (!_warned && remaining <= 30) {
      _warned = true;
      _play('warn.mp3');
    }

    // Landing detection for dropping block
    final moving = _moving;
    if (moving != null && moving.isDropping) {
      final prev = _stack.last;
      final movingBottom = moving.position.y + moving.size.y;
      final prevTop = prev.position.y;
      if (movingBottom >= prevTop) {
        _onBlockLanded(moving, prev);
      }
    }

    // Move the world root so the top of the stack stays around 35% from top.
    final peakY = _stack.isEmpty
        ? _initialViewY
        : _stack.map((b) => b.position.y).reduce(math.min);
    final desiredScreenY = size.y * 0.35;
    double offset = desiredScreenY - peakY;
    // Do not move the world upward at start (keep >= 0 so it only moves down).
    if (offset < 0) offset = 0;
    final currentWorldY = worldRoot.position.y;
    final newWorldY = currentWorldY + (offset - currentWorldY) * math.min(1, dt * 6);
    worldRoot.position = Vector2(worldRoot.position.x, newWorldY);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (phase != GamePhase.playing) return;
    if (overlays.isActive('Tutorial')) {
      overlays.remove('Tutorial');
      // Start horizontal motion for the first block now
      if (_moving != null && _stack.length == 1) {
        _moving!.horizontalSpeed = _speed;
      }
      return; // first tap only dismisses the tutorial
    }
    final moving = _moving;
    if (moving != null && !moving.isDropping) {
      moving.isDropping = true;
      _play('drop.mp3');
    }
  }

  int _colorIndex = 0;

  Future<void> _spawnMovingBlock() async {
    final color = doc_colors.blockColors[_colorIndex % doc_colors.blockColors.length];
    _colorIndex++;
    _speed = math.min(maxHorizontalSpeed, _speed * 1.06); // ramp up to higher cap
    final last = _stack.last;
    // Width rule: first user block has a reasonable fixed cap, thereafter match last stacked width
    final double currentWidth = (_stack.length == 1)
        ? math.min(_initialBlockSize.x, size.x * 0.8) // limit first width for gameplay
        : last.size.x;
    final startY = last.position.y - _initialBlockSize.y * 1.8;
    // First moving block: start centered above base. Others can start from left.
    final startX = (_stack.length == 1)
        ? (size.x - currentWidth) / 2
        : 0.0;
    final block = bb.StackBlock(
      position: Vector2(startX, startY),
      size: Vector2(currentWidth, _initialBlockSize.y),
      color: color,
    )
      ..horizontalSpeed = _speed
      ..direction = 1
      ..maxX = size.x - currentWidth
      ..wrap = (_stack.length == 1); // infinite wrap for the first moving block
    worldRoot.add(block);
    _moving = block;

    // Prepare logo overlay selection by contrast; load if asset exists
    final logoPath = logoForColor(color);
    try {
      final sprite = Sprite(images.fromCache(logoPath));
      final desiredH = block.size.y * 0.6;
      final src = sprite.srcSize;
      final aspect = src.y == 0 ? 1.0 : (src.x / src.y);
      final logoSize = Vector2(desiredH * aspect, desiredH);
      // Ensure at least the logo can fit visibly (8px padding each side)
      block.minWidth = math.max(block.minWidth, logoSize.x + 16);
      final logo = SpriteComponent(
        sprite: sprite,
        size: logoSize,
        anchor: Anchor.centerLeft,
        position: Vector2(8, block.size.y / 2),
      );
      // Clip logo to block bounds so it won't overflow on narrow blocks
      final clip = ClipComponent.rectangle(
        size: block.size.clone(),
        position: Vector2.zero(),
        anchor: Anchor.topLeft,
      );
      clip.add(logo);
      block.add(clip);
    } catch (e) {
      debugPrint('Logo load failed for $logoPath: $e');
      // No fallback assets to avoid bad asset keys on web; skip logo.
    }
  }

  void _onBlockLanded(bb.StackBlock moving, bb.StackBlock prev) {
    // Snap moving to sit on top of prev
    moving.position.y = prev.position.y - moving.size.y;

    final movingLeft = moving.position.x;
    final movingRight = movingLeft + moving.size.x;
    double overlapLeft;
    double overlapRight;
    double overlapWidth;
    if (prev.infiniteWidth) {
      overlapLeft = movingLeft;
      overlapRight = movingRight;
      overlapWidth = moving.size.x;
    } else {
      final prevLeft = prev.position.x;
      final prevRight = prevLeft + prev.size.x;
      overlapLeft = math.max(movingLeft, prevLeft);
      overlapRight = math.min(movingRight, prevRight);
      overlapWidth = overlapRight - overlapLeft;
    }

    // Perfect check: >=95% overlap of previous block width (not applicable for infinite base)
    final bool isPrecision = prev.infiniteWidth
        ? false
        : (overlapWidth / prev.size.x) >= 0.95;

    if (overlapWidth <= 0) {
      // Game over
      phase = GamePhase.gameOver;
      _moving = null;
      overlays.add('GameOver');
      _play('gameover.mp3');
      return;
    }

    // Trim the moving block to the overlap region (UI rounding does not affect gameplay)
    if (overlapWidth < moving.size.x) {
      // Spawn simple fragment effect for trimmed part(s)
      final leftTrimWidth = (overlapLeft > movingLeft) ? (overlapLeft - movingLeft) : 0.0;
      final rightTrimWidth = (movingRight > overlapRight) ? (movingRight - overlapRight) : 0.0;
      if (leftTrimWidth > 0) {
        _spawnFragment(Vector2(movingLeft, moving.position.y), Vector2(leftTrimWidth, moving.size.y), moving.color);
      }
      if (rightTrimWidth > 0) {
        _spawnFragment(Vector2(overlapRight, moving.position.y), Vector2(rightTrimWidth, moving.size.y), moving.color);
      }
      // Apply minWidth constraint: keep at least minWidth but never exceed prev width
      double newLeft = overlapLeft;
      double newWidth = overlapWidth;
      if (!prev.infiniteWidth) {
        final double prevLeft = prev.position.x;
        final double prevRight = prevLeft + prev.size.x;
        final center = (overlapLeft + overlapRight) / 2;
        final double minAllowed = moving.minWidth.clamp(0, prev.size.x);
        newWidth = math.max(overlapWidth, minAllowed);
        newLeft = (center - newWidth / 2).clamp(prevLeft, prevRight - newWidth);
      }
      moving.position.x = newLeft;
      moving.size.x = newWidth;
      // If there is a clipping container for the logo, keep its size in sync
      for (final c in moving.children) {
        if (c is ClipComponent) {
          c.size = moving.size.clone();
        }
      }
      _play('trim.mp3');
    }

    // Finalize landing
    moving.isDropping = false;
    moving.frozen = true; // freeze landed blocks; they won't move anymore
    _stack.add(moving);
    _moving = null;

    // Update score and stack top
    int addScore = overlapWidth.round();
    if (isPrecision) {
      _combo += 1;
      addScore += 50 + 25 * (_combo - 1);
      // Offset floating texts to avoid overlap when triggered rapidly
      var basePos = moving.center.clone();
      final existing = children.whereType<FloatingText>().length;
      basePos.y -= (existing * 12);
      worldRoot.add(FloatingText(text: 'Precision! x$_combo', position: basePos));
      if (comboVN.value != _combo) comboVN.value = _combo;
    } else {
      _combo = 0;
      if (comboVN.value != 0) comboVN.value = 0;
    }
    score += addScore;
    scoreVN.value = score;
    stackTop.setValues(moving.position.x, moving.position.y);
    _play('land.mp3');

    // Spawn next
    _spawnMovingBlock();

    // Show a random brand quote just above the landed block
    _showRandomQuote(Vector2(moving.center.x, moving.position.y - 8));
  }

  void _showRandomQuote(Vector2 pos) {
    try {
      final quotes = brandQuotes;
      if (quotes.isEmpty) return;
      final idx = math.Random().nextInt(quotes.length);
      worldRoot.add(QuoteBanner(text: quotes[idx], position: pos));
    } catch (_) {
      // If import path changes or list missing, fail silently
    }
  }

  void _spawnFragment(Vector2 pos, Vector2 size, Color color) {
    final rand = math.Random();
    int count = size.x < 20 ? 1 : math.min(6, (size.x / 10).round());
    double x = pos.x;
    double remaining = size.x;
    for (int i = 0; i < count; i++) {
      final minW = 6.0;
      final maxW = 18.0;
      final target = (minW + rand.nextDouble() * (maxW - minW));
      final shardW = i == count - 1 ? remaining : math.min(remaining, target);
      final shardPos = Vector2(x, pos.y);
      final shardSize = Vector2(shardW, size.y * (0.6 + rand.nextDouble() * 0.4));
      final vx = (rand.nextDouble() * 240 - 120);
      final vy = 520 + rand.nextDouble() * 380;
      final vr = (rand.nextDouble() * 4 - 2); // -2..2 rad/s
      const life = 0.7;
      worldRoot.add(Fragment(position: shardPos, size: shardSize, color: color, vx: vx, vy: vy, angularVelocity: vr, life: life));
      x += shardW;
      remaining -= shardW;
      if (remaining <= 0) break;
    }
  }

  Future<void> _play(String file) async {
    // Route to an available pool; cap concurrency via maxPlayers.
    final String alt = file.endsWith('.wav') ? file.replaceAll('.wav', '.mp3') : file.replaceAll('.mp3', '.wav');
    for (final key in [file, alt]) {
      final pool = _pools[key];
      if (pool != null) {
        try {
          await pool.start();
          return;
        } catch (_) {
          // pool busy or platform issue; try next
        }
      }
    }
  }
}
