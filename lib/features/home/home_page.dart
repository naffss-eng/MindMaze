import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'eight_puzzle.dart';
import 'n_queen_game.dart';
import 'water_jug_game.dart'; // Ensure this file exists in your lib folder

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: HomePage(),
  ));
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController rainController;
  late AnimationController glowController;
  late Timer glitchTimer;
  bool glitch = false;

  @override
  void initState() {
    super.initState();
    rainController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    glowController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

    glitchTimer = Timer.periodic(const Duration(milliseconds: 3000), (_) {
      if (mounted) {
        setState(() => glitch = true);
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => glitch = false);
        });
      }
    });
  }

  @override
  void dispose() {
    rainController.dispose();
    glowController.dispose();
    glitchTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;

              return Stack(
                children: [
                  // 1. ARCADE BACKGROUND
                  Positioned.fill(
                    child: Image.asset("assets/images/arcade.png", fit: BoxFit.fill),
                  ),

                  // 2. THE SCREEN AREA
                  Positioned(
                    left: w * 0.11,
                    right: w * 0.11,
                    top: h * 0.02,
                    bottom: h * 0.485,
                    child: ClipRect(
                      child: Container(
                        color: Colors.black,
                        child: Stack(
                          children: [
                            // BACKGROUND FX (Rain)
                            AnimatedBuilder(
                              animation: rainController,
                              builder: (_, __) => CustomPaint(
                                painter: _OrbRainPainter(rainController.value),
                                size: Size.infinite,
                              ),
                            ),
                            
                            // 3D GRID
                            const Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              height: 120,
                              child: IgnorePointer(child: _PerspectiveGridWidget()),
                            ),

                            // FRONT UI LAYER (Tiles must be on top)
                            Center(
                              child: Transform.translate(
                                offset: glitch ? const Offset(2, 0) : Offset.zero,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _PermanentGlowTitle(glitch: glitch, glow: glowController),
                                    _Subtitle(glitch: glitch),
                                    const SizedBox(height: 35),
                                    
                                    // 8-PUZZLE TILE (Navigation Trigger)
                                    _GameTile(
                                      icon: Icons.grid_on,
                                      label: "8 PUZZLE",
                                      glow: glowController,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const EightPuzzleGame()),
                                        );
                                      },
                                    ),

                                    _GameTile(
                                      icon: Icons.workspace_premium, // crown icon
                                      label: "N-QUEEN",
                                      glow: glowController,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const NQueenGame()),
                                       );
                                     }, 
                                    ),
                                    _GameTile(
                                      icon: Icons.water_drop, // water jug icon
                                      label: "WATER JUG",
                                      glow: glowController,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const WaterJugGame()),
                                       );
                                     },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// --- REFINED TILE WIDGET WITH TAP FIX ---
class _GameTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Animation<double> glow;
  final VoidCallback? onTap;

  const _GameTile({required this.icon, required this.label, required this.glow, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque, // Force tap detection
        onTap: onTap,
        child: AnimatedBuilder(
          animation: glow,
          builder: (context, child) {
            return Container(
              width: 250,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
              decoration: BoxDecoration(
                color: Color.lerp(const Color(0xFF140824), Colors.pinkAccent.withOpacity(0.3), glow.value),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.yellowAccent.withOpacity(0.7), 
                  width: 2
                ),
                boxShadow: [
                  BoxShadow(color: Colors.pinkAccent.withOpacity(0.15), blurRadius: 10)
                ],
              ),
              child: Row(
                children: [
                  Icon(icon, color: Colors.yellowAccent, size: 26),
                  const SizedBox(width: 18),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white, 
                      fontSize: 18, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// --- GRID WIDGET (Wrapped in IgnorePointer in the stack) ---
class _PerspectiveGridWidget extends StatelessWidget {
  const _PerspectiveGridWidget();
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GridPainter());
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.pinkAccent
      ..strokeWidth = 1.2
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 1);

    final centerX = size.width / 2;
    for (double i = -1.5; i <= 2.5; i += 0.4) {
      canvas.drawLine(
        Offset(centerX, 0), 
        Offset(size.width * i, size.height), 
        paint..color = Colors.pinkAccent.withOpacity(0.4)
      );
    }
    for (int i = 0; i < 10; i++) {
      double yPos = size.height * pow(i / 10, 1.6);
      canvas.drawLine(
        Offset(0, yPos), 
        Offset(size.width, yPos), 
        paint..color = Colors.pinkAccent.withOpacity((i / 10).clamp(0.0, 0.8))
      );
    }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// --- RAIN PAINTER ---
class _OrbRainPainter extends CustomPainter {
  final double progress;
  _OrbRainPainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final r = Random(42);
    for (int i = 0; i < 60; i++) {
      double x = (size.width / 60) * i;
      double yBase = (progress * size.height * (0.6 + r.nextDouble())) % size.height;
      for (int j = 0; j < 15; j++) {
        canvas.drawCircle(
          Offset(x, yBase - (j * 12)), 
          1.0, 
          Paint()..color = Colors.orangeAccent.withOpacity((1 - j / 15) * 0.8)
        );
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// --- TITLE WIDGET ---
class _PermanentGlowTitle extends StatelessWidget {
  final bool glitch;
  final Animation<double> glow;
  const _PermanentGlowTitle({required this.glitch, required this.glow});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glow,
      builder: (context, child) => Text(
        "MINDMAZE",
        style: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w900,
          color: Colors.yellowAccent,
          shadows: [
            Shadow(color: Colors.orange, blurRadius: 20 + (glow.value * 15)),
            if (glitch) ...[
              const Shadow(color: Colors.cyanAccent, offset: Offset(-5, 0)),
              const Shadow(color: Colors.redAccent, offset: Offset(5, 0))
            ]
          ]
        )
      ),
    );
  }
}

class _Subtitle extends StatelessWidget {
  final bool glitch;
  const _Subtitle({required this.glitch});
  @override
  Widget build(BuildContext context) {
    return Text(
      "INSERT LOGIC",
      style: TextStyle(
        color: Colors.pinkAccent,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 8,
        shadows: const [Shadow(color: Colors.pink, blurRadius: 10)]
      )
    );
  }
}