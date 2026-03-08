import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EightPuzzleGame extends StatefulWidget {
  const EightPuzzleGame({super.key});

  @override
  State<EightPuzzleGame> createState() => _EightPuzzleGameState();
}

class _EightPuzzleGameState extends State<EightPuzzleGame> {
  List<int> board = [1, 2, 3, 4, 5, 6, 7, 8, 0];
  List<int> initialBoard = [];
  int emptyIndex = 8;
  int moves = 0;
  int seconds = 0;
  int bestTime = 99999;
  Timer? timer;
  bool solving = false;
  bool isWinDialogOpen = false;
  bool showHints = false; 
  String difficulty = "Medium";
  
  Map<String, List<int>> difficultyRanges = {
    "Easy": [6, 10],
    "Medium": [13, 16],
    "Hard": [18, 22],
  };

  late ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    _loadBestTime();
    _generateNewGame();
  }

  @override
  void dispose() {
    timer?.cancel();
    _confetti.dispose();
    super.dispose();
  }

  void _playWhoosh() => HapticFeedback.selectionClick();
  void _playWinSound() => HapticFeedback.vibrate();

  Future<void> _loadBestTime() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => bestTime = prefs.getInt("best_$difficulty") ?? 99999);
  }

  Future<void> _saveBestTime() async {
    final prefs = await SharedPreferences.getInstance();
    if (seconds < bestTime) {
      bestTime = seconds;
      await prefs.setInt("best_$difficulty", bestTime);
    }
  }

  void _startTimer() {
    timer?.cancel();
    seconds = 0;
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => seconds++);
    });
  }

  void _generateNewGame() {
    Random r = Random();
    List<int> newBoard;
    while (true) {
      newBoard = [1, 2, 3, 4, 5, 6, 7, 8, 0];
      int empty = 8;
      for (int i = 0; i < 200; i++) {
        List<int> valid = _validMoves(empty);
        int swap = valid[r.nextInt(valid.length)];
        newBoard[empty] = newBoard[swap];
        newBoard[swap] = 0;
        empty = swap;
      }
      int dist = _manhattan(newBoard);
      if (dist >= difficultyRanges[difficulty]![0] && dist <= difficultyRanges[difficulty]![1]) {
        emptyIndex = newBoard.indexOf(0);
        break;
      }
    }
    setState(() {
      board = newBoard;
      initialBoard = List.from(newBoard);
      moves = 0;
      solving = false;
      isWinDialogOpen = false;
    });
    _loadBestTime();
    _startTimer();
  }

  void _resetGame() {
    setState(() {
      board = List.from(initialBoard);
      emptyIndex = board.indexOf(0);
      moves = 0;
      solving = false;
    });
    _startTimer();
  }

  List<int> _validMoves(int index) {
    List<int> m = [];
    int r = index ~/ 3, c = index % 3;
    if (r > 0) m.add(index - 3);
    if (r < 2) m.add(index + 3);
    if (c > 0) m.add(index - 1);
    if (c < 2) m.add(index + 1);
    return m;
  }

  // UPDATED SWIPE: Highly sensitive for fast play
  void _handleSwipe(DragEndDetails details) {
    if (solving) return;
    double dx = details.velocity.pixelsPerSecond.dx;
    double dy = details.velocity.pixelsPerSecond.dy;
    
    // Low threshold (80) means even small fast flicks trigger a move
    const double threshold = 80.0; 
    int targetIndex = -1;
    int r = emptyIndex ~/ 3, c = emptyIndex % 3;

    if (dx.abs() > dy.abs()) {
      if (dx > threshold && c > 0) targetIndex = emptyIndex - 1; 
      else if (dx < -threshold && c < 2) targetIndex = emptyIndex + 1;
    } else {
      if (dy > threshold && r > 0) targetIndex = emptyIndex - 3; 
      else if (dy < -threshold && r < 2) targetIndex = emptyIndex + 3;
    }
    
    if (targetIndex != -1) _moveTile(targetIndex);
  }

  void _moveTile(int index) {
    if (solving) return;
    _playWhoosh();
    setState(() {
      board[emptyIndex] = board[index];
      board[index] = 0;
      emptyIndex = index;
      moves++; 
    });
    if (_isSolved()) _handleWin();
  }

  bool _isSolved() {
    for (int i = 0; i < 8; i++) if (board[i] != i + 1) return false;
    return board[8] == 0;
  }

  int _manhattan(List<int> state) {
    int total = 0;
    for (int i = 0; i < 9; i++) {
      if (state[i] != 0) {
        int val = state[i] - 1;
        total += (val ~/ 3 - i ~/ 3).abs() + (val % 3 - i % 3).abs();
      }
    }
    return total;
  }

  Future<void> _solveWithAI() async {
    solving = true;
    timer?.cancel();
    List<List<int>> solution = _aStar(board);
    for (var state in solution) {
      // Faster AI delay to match smoother animations
      await Future.delayed(const Duration(milliseconds: 160));
      if (!mounted) return;
      _playWhoosh();
      setState(() {
        board = state;
        emptyIndex = board.indexOf(0);
        moves++; 
      });
    }
    solving = false;
    if (_isSolved()) _handleWin();
  }

  List<List<int>> _aStar(List<int> start) {
    List<int> goal = [1, 2, 3, 4, 5, 6, 7, 8, 0];
    List<_Node> open = [_Node(start, null, 0, _manhattan(start))];
    Set<String> closed = {};
    while (open.isNotEmpty) {
      open.sort((a, b) => a.f.compareTo(b.f));
      _Node current = open.removeAt(0);
      if (current.state.toString() == goal.toString()) return _reconstruct(current);
      closed.add(current.state.toString());
      int empty = current.state.indexOf(0);
      for (int move in _validMoves(empty)) {
        List<int> newState = List.from(current.state);
        newState[empty] = newState[move];
        newState[move] = 0;
        if (closed.contains(newState.toString())) continue;
        open.add(_Node(newState, current, current.g + 1, _manhattan(newState)));
      }
    }
    return [];
  }

  List<List<int>> _reconstruct(_Node node) {
    List<List<int>> path = [];
    while (node.parent != null) {
      path.insert(0, node.state);
      node = node.parent!;
    }
    return path;
  }

  Map<String, dynamic> _getRank(int currentMoves, int optimalMoves) {
    int diff = currentMoves - optimalMoves;
    if (diff <= 2) return {"rank": "S", "color": Colors.yellowAccent};
    if (diff <= 10) return {"rank": "A", "color": Colors.greenAccent};
    if (diff <= 25) return {"rank": "B", "color": Colors.cyanAccent};
    return {"rank": "C", "color": Colors.pinkAccent};
  }

  void _handleWin() async {
    timer?.cancel();
    _playWinSound();
    int optimal = _manhattan(initialBoard);
    var rankData = _getRank(moves, optimal);
    await _saveBestTime();
    _confetti.play();
    setState(() => isWinDialogOpen = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 380, height: 620,
            decoration: const BoxDecoration(
              image: DecorationImage(image: AssetImage("assets/images/complete.jpg"), fit: BoxFit.contain),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 52, left: 0, right: 0,
                  child: Center(child: Text("CONGRATULATIONS", style: GoogleFonts.pressStart2p(color: Colors.pinkAccent, fontSize: 13))),
                ),
                Positioned(
                  top: 72, left: 0, right: 0,
                  child: Center(child: Text("LEVEL UP WITH ME", style: GoogleFonts.pressStart2p(color: Colors.cyanAccent, fontSize: 8))),
                ),
                Positioned(
                  top: 115, left: 0, right: 0,
                  child: Column(
                    children: [
                      Text("RANK", style: GoogleFonts.pressStart2p(color: Colors.white, fontSize: 10)),
                      const SizedBox(height: 8),
                      Text(rankData["rank"], 
                        style: GoogleFonts.pressStart2p(
                          color: rankData["color"], 
                          fontSize: 45,
                          shadows: [Shadow(color: rankData["color"], blurRadius: 20)]
                        )
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 215, left: 75, right: 75,
                  child: Column(
                    children: [
                      _arcadeStatLine("TIME", "$seconds s", (30 / seconds).clamp(0.1, 1.0)),
                      _arcadeStatLine("MOVES", "$moves", (optimal / moves).clamp(0.1, 1.0)),
                      _arcadeStatLine("OPTIMAL", "$optimal", 1.0),
                      _arcadeStatLine("BEST", bestTime == 99999 ? "--" : "$bestTime s", 0.8),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 85, right: 38,
                  child: GestureDetector(
                    onTap: () { Navigator.pop(context); _generateNewGame(); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black, borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.cyanAccent, width: 2),
                        boxShadow: [const BoxShadow(color: Colors.cyanAccent, blurRadius: 10)],
                      ),
                      child: Text("NEW GAME", style: GoogleFonts.pressStart2p(color: Colors.cyanAccent, fontSize: 8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _arcadeStatLine(String label, String value, double progress) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite, color: Colors.pinkAccent, size: 12),
              const SizedBox(width: 8),
              Text("$label: $value", style: GoogleFonts.pressStart2p(color: Colors.white, fontSize: 8)),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 8, width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 1),
              color: Colors.black.withOpacity(0.3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress, 
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.greenAccent,
                  boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.5), blurRadius: 5)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // OPTIMIZED TILE DESIGN: RepaintBoundary prevents lag from text/shadows
  Widget _tileDesign(int value, int currentIndex) {
    const List<Color> glows = [Colors.cyanAccent, Colors.pinkAccent, Colors.greenAccent, Colors.purpleAccent, Colors.yellowAccent, Colors.orangeAccent, Colors.blueAccent, Colors.redAccent];
    Color myGlow = glows[(value - 1) % glows.length];

    int goalIndex = value - 1;
    int dist = (goalIndex ~/ 3 - currentIndex ~/ 3).abs() + (goalIndex % 3 - currentIndex % 3).abs();

    return RepaintBoundary(
      child: Container(
        width: 106, height: 106,
        decoration: BoxDecoration(
          color: Colors.black45,
          border: Border.all(color: myGlow.withOpacity(0.5), width: 1),
          boxShadow: [BoxShadow(color: myGlow.withOpacity(0.3), blurRadius: 10, spreadRadius: 1)],
        ),
        child: Stack(
          children: [
            Positioned(top: 5, left: 5, child: Icon(Icons.grid_3x3, size: 8, color: myGlow.withOpacity(0.7))),
            Positioned(bottom: 5, right: 5, child: Icon(Icons.bolt, size: 8, color: myGlow.withOpacity(0.7))),
            
            if (showHints)
              Positioned(
                top: 5, right: 8,
                child: Text(dist == 0 ? "OK" : "D:$dist", 
                    style: GoogleFonts.pressStart2p(fontSize: 7, color: dist == 0 ? Colors.greenAccent : Colors.redAccent)),
              ),

            Center(
              child: Text("$value",
                  style: GoogleFonts.pressStart2p(fontSize: 22, color: Colors.white, shadows: [Shadow(color: myGlow, blurRadius: 12)])),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset("assets/images/vapor.jpg", fit: BoxFit.cover)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Visibility(
                        visible: !isWinDialogOpen,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), border: Border.all(color: Colors.pinkAccent, width: 2)),
                            child: Text("< EXIT", style: GoogleFonts.pressStart2p(fontSize: 8, color: Colors.pinkAccent)),
                          ),
                        ),
                      ),
                      Visibility(visible: !isWinDialogOpen, child: _difficultySelector()),
                      const SizedBox(width: 50), 
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Visibility(visible: !isWinDialogOpen, child: _statsBar()),
                const Spacer(),
                _board(), 
                const Spacer(),
                Visibility(visible: !isWinDialogOpen, child: _buttons()),
                const SizedBox(height: 20)
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(confettiController: _confetti, blastDirectionality: BlastDirectionality.explosive),
          )
        ],
      ),
    );
  }

  Widget _difficultySelector() {
    return Row(
      children: ["Easy", "Medium", "Hard"].map((d) {
        bool isSelected = difficulty == d;
        return GestureDetector(
          onTap: () { setState(() => difficulty = d); _generateNewGame(); },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(color: Colors.black, border: Border.all(color: isSelected ? Colors.cyanAccent : Colors.white24, width: 2)),
            child: Text(d, style: GoogleFonts.pressStart2p(fontSize: 7, color: isSelected ? Colors.cyanAccent : Colors.white)),
          ),
        );
      }).toList(),
    );
  }

  Widget _statsBar() {
    return Text("TIME:$seconds  MOVES:$moves  DIST:${_manhattan(board)}",
        style: GoogleFonts.pressStart2p(fontSize: 9, color: Colors.white));
  }

  // OPTIMIZED BOARD: ValueKey and easeOutQuart curve provide butter-smooth motion
  Widget _board() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanEnd: _handleSwipe, 
      child: Container(
        width: 336, height: 336,
        decoration: BoxDecoration(color: Colors.transparent, border: Border.all(color: Colors.cyanAccent.withOpacity(0.3), width: 2)),
        child: Stack(
          clipBehavior: Clip.none,
          children: List.generate(9, (index) {
            int val = board[index];
            if (val == 0) return const SizedBox.shrink();
            return AnimatedPositioned(
              key: ValueKey(val), // Unique key allows Flutter to track the tile's motion
              duration: const Duration(milliseconds: 140), 
              curve: Curves.easeOutQuart, 
              left: (index % 3) * 110.0, 
              top: (index ~/ 3) * 110.0,
              child: _tileDesign(val, index),
            );
          }),
        ),
      ),
    );
  }

  Widget _buttons() {
    return Wrap(
      spacing: 10, runSpacing: 10, alignment: WrapAlignment.center,
      children: [
        _btn("AI SOLVE", Colors.greenAccent, _solveWithAI),
        _btn("RESET", Colors.orangeAccent, _resetGame),
        _btn("NEW", Colors.cyanAccent, _generateNewGame),
        _btn(showHints ? "HIDE HINT" : "SHOW HINT", Colors.purpleAccent, () {
          setState(() => showHints = !showHints);
        }),
      ],
    );
  }

  Widget _btn(String text, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(backgroundColor: Colors.black, side: BorderSide(color: color)),
      child: Text(text, style: GoogleFonts.pressStart2p(fontSize: 8, color: color)),
    );
  }
}

class _Node {
  List<int> state; _Node? parent; int g; int h;
  int get f => g + h;
  _Node(this.state, this.parent, this.g, this.h);
}