import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mindmaze/features/home/home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<double> _scale;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutExpo),
    );

    _glow = Tween<double>(begin: 10, end: 40).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();

    Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          // 🔥 Cyberpunk Tunnel Background
          Positioned.fill(
            child: Image.asset(
              "assets/images/bg.jpg",
              fit: BoxFit.cover,
            ),
          ),

          // 🔥 Slight dark overlay for logo readability
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.35),
            ),
          ),

          // 🔥 Center Logo Animation
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scale.value,
                    child: Container(
                      width: 300,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withOpacity(0.8),
                            blurRadius: _glow.value,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        "assets/images/mindmaze_logo.png",
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 🔥 Subtle Loading Text
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: FadeTransition(
                opacity: _fade,
                child: const Text(
                  "Initializing Neural Systems...",
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 14,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(
                        blurRadius: 20,
                        color: Colors.cyanAccent,
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}