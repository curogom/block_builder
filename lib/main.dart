import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/stack_game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final game = StackGame();
  runApp(GameApp(game: game));
}

class GameApp extends StatelessWidget {
  const GameApp({super.key, required this.game});
  final StackGame game;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Block Builder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00BFA6)),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: GameWidget<StackGame>(
          game: game,
          overlayBuilderMap: {
            'Hud': (context, g) => SafeArea(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(0, 0, 0, 0.35),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DefaultTextStyle(
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Image(
                                image: AssetImage('assets/images/logo_imweb_white.webp'),
                                height: 16,
                                filterQuality: FilterQuality.medium,
                              ),
                              const SizedBox(width: 10),
                              ValueListenableBuilder<int>(
                                valueListenable: g.timeVN,
                                builder: (_, value, __) => Text('Time: ${value}s'),
                              ),
                              const SizedBox(width: 12),
                              ValueListenableBuilder<int>(
                                valueListenable: g.scoreVN,
                                builder: (_, value, __) => Text('Score: $value'),
                              ),
                              const SizedBox(width: 16),
                              InkWell(
                                onTap: () {
                                  if (g.phase == GamePhase.paused) {
                                    g.phase = GamePhase.playing;
                                    g.overlays.remove('Paused');
                                  } else if (g.phase == GamePhase.playing) {
                                    g.phase = GamePhase.paused;
                                    g.overlays.add('Paused');
                                  }
                                },
                                child: const Icon(Icons.pause, color: Colors.white, size: 18),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            'Paused': (context, g) => Container(
                  color: const Color.fromRGBO(0, 0, 0, 0.5),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Paused', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            g.phase = GamePhase.playing;
                            g.overlays.remove('Paused');
                          },
                          child: const Text('Resume'),
                        ),
                      ],
                    ),
                  ),
                ),
            'GameOver': (context, g) => Container(
                  color: const Color.fromRGBO(0, 0, 0, 0.6),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Game Over', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Score: ${g.score}', style: const TextStyle(color: Colors.white, fontSize: 18)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            // Simple restart: recreate game
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => GameApp(game: StackGame())),
                            );
                          },
                          child: const Text('Restart'),
                        ),
                      ],
                    ),
                  ),
                ),
            'Tutorial': (context, g) => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => g.overlays.remove('Tutorial'),
                  child: Container(
                    color: const Color.fromRGBO(0, 0, 0, 0.45),
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.all(24),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(20, 26, 34, 0.95),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('How to Play', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                            SizedBox(height: 10),
                            Text('• 블록이 좌우로 이동합니다', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            Text('• 화면을 탭하면 블록이 떨어집니다', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            Text('• 겹친 면적만 다음 층으로 남습니다', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            Text('• 3분 안에 최대 높이에 도전!', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            SizedBox(height: 14),
                            Text('화면을 탭하면 시작합니다', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          },
          initialActiveOverlays: const ['Hud'],
        ),
      ),
    );
  }
}
