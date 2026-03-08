import 'package:flutter/material.dart';
import 'features/splash/splash_screen.dart';

void main() {
  runApp(const MindMazeApp());
}

class MindMazeApp extends StatelessWidget {
  const MindMazeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MindMaze',
      theme: ThemeData.dark(),
      home: const SplashScreen(),
    );
  }
}