import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';

class NQueenGame extends StatefulWidget {
  const NQueenGame({super.key});

  @override
  State<NQueenGame> createState() => _NQueenGameState();
}

class _NQueenGameState extends State<NQueenGame> {
  int size = 8;
  late List<int> queens;

  bool solving = false;
  int? hintRow;
  int? hintCol;

  int seconds = 0;
  Timer? timer;

  Map<int, int> bestTimes = {};
  late ConfettiController confetti;

  // ================= INIT =================

  @override
  void initState() {
    super.initState();
    confetti = ConfettiController(duration: const Duration(seconds: 3));
    _initializeBoard();
    _loadBestTimes();
  }

  @override
  void dispose() {
    timer?.cancel();
    confetti.dispose();
    super.dispose();
  }

  void _initializeBoard() {
    queens = List.filled(size, -1);
    solving = false;
    hintRow = null;
    hintCol = null;
    _startTimer();
    setState(() {});
  }

  // ================= TIMER =================

  void _startTimer() {
    timer?.cancel();
    seconds = 0;
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => seconds++);
    });
  }

  // ================= STORAGE =================

  Future<void> _loadBestTimes() async {
    final prefs = await SharedPreferences.getInstance();
    for (int s in [4, 6, 8, 10, 12]) {
      bestTimes[s] = prefs.getInt("best_$s") ?? 0;
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveBestTime() async {
    final prefs = await SharedPreferences.getInstance();
    if (bestTimes[size] == 0 || seconds < bestTimes[size]!) {
      bestTimes[size] = seconds;
      await prefs.setInt("best_$size", seconds);
    }
  }

  // ================= LOGIC =================

  bool _isSafe(int row, int col) {
    for (int c = 0; c < size; c++) {
      if (c == col) continue;
      int r = queens[c];
      if (r == -1) continue;
      if (r == row) return false;
      if ((r - row).abs() == (c - col).abs()) return false;
    }
    return true;
  }

  // UPDATED: Now returns true if row, diagonal, OR column is occupied
  bool _isAttacked(int row, int col) {
    // Check if there is a queen anywhere in this specific column
    if (queens[col] != -1) return true;

    for (int c = 0; c < size; c++) {
      if (c == col) continue;
      int r = queens[c];
      if (r == -1) continue;
      if (r == row) return true; // Row attack
      if ((r - row).abs() == (c - col).abs()) return true; // Diagonal attack
    }
    return false;
  }

  int get placedCount => queens.where((q) => q != -1).length;

  bool _isSolved() {
    if (queens.contains(-1)) return false;
    for (int col = 0; col < size; col++) {
      if (!_isSafe(queens[col], col)) return false;
    }
    return true;
  }

  void _placeQueen(int row, int col) {
    if (solving) return;
    setState(() {
      hintRow = null;
      hintCol = null;
      if (queens[col] == row) {
        queens[col] = -1;
      } else {
        queens[col] = row;
      }
    });
    if (_isSolved()) _handleWin();
  }

  // ================= HINT =================

  void _getHint() {
    if (solving) return;
    int nextCol = queens.indexOf(-1);
    
    if (nextCol == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Board is full! Clear a queen to get a hint.", 
            style: GoogleFonts.pressStart2p(fontSize: 8)),
          backgroundColor: Colors.blueGrey.withOpacity(0.9),
        ),
      );
      return;
    }

    bool found = false;
    for (int r = 0; r < size; r++) {
      if (_isSafe(r, nextCol)) {
        setState(() {
          hintRow = r;
          hintCol = nextCol;
        });
        found = true;
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() { hintRow = null; hintCol = null; });
        });
        break;
      }
    }

    if (!found) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No hints available! Move your previous queens.", 
            style: GoogleFonts.pressStart2p(fontSize: 8, color: Colors.yellowAccent)),
          backgroundColor: Colors.redAccent.withOpacity(0.8),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ================= AI SOLVER =================

  Future<bool> _solve(int col) async {
    if (!solving) return false;
    if (col >= size) return true;
    for (int row = 0; row < size; row++) {
      if (!solving) return false;
      if (_isSafe(row, col)) {
        if (!mounted) return false;
        setState(() => queens[col] = row);
        await Future.delayed(const Duration(milliseconds: 180));
        if (await _solve(col + 1)) return true;
        if (!mounted) return false;
        setState(() => queens[col] = -1);
        await Future.delayed(const Duration(milliseconds: 120));
      }
    }
    return false;
  }

  Future<void> _startAI() async {
    if (solving) return;
    solving = true;
    timer?.cancel();
    queens = List.filled(size, -1);
    setState(() {});
    bool solved = await _solve(0);
    solving = false;
    if (solved && mounted) _handleWin();
  }

  // ================= VICTORY =================

  void _handleWin() async {
    timer?.cancel();
    await _saveBestTime();
    confetti.play();

    int best = bestTimes[size] ?? 0;
    String tier = (best == seconds) ? "S TIER" : (seconds <= best + (size * 2) ? "A TIER" : "B TIER");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.85), Colors.black.withOpacity(0.95)],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 40,
            ),
          ),
          Center(
            child: TweenAnimationBuilder(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutBack,
              builder: (context, value, child) => Transform.scale(scale: value, child: child),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("👑 CONGRATULATIONS 👑", style: GoogleFonts.pressStart2p(fontSize: 14, color: Colors.yellowAccent, decoration: TextDecoration.none)),
                  const SizedBox(height: 15),
                  Text(tier, style: GoogleFonts.pressStart2p(fontSize: 10, color: Colors.cyanAccent, decoration: TextDecoration.none)),
                  const SizedBox(height: 30),
                  _victoryStat("BOARD", "$size x $size"),
                  _victoryStat("TIME", "$seconds s"),
                  _victoryStat("BEST", "$best s"),
                  const SizedBox(height: 35),
                  ElevatedButton(
                    onPressed: () { Navigator.pop(context); _initializeBoard(); },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.yellowAccent, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14)),
                    child: Text("NEW GAME", style: GoogleFonts.pressStart2p(fontSize: 9, color: Colors.black)),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _victoryStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.pressStart2p(fontSize: 9, color: Colors.white70, decoration: TextDecoration.none)),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.pressStart2p(fontSize: 13, color: Colors.white, decoration: TextDecoration.none)),
        ],
      ),
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    double boardSize = 330;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset("assets/images/n_queen.jpg", fit: BoxFit.cover)),
          SafeArea(
            child: Column(
              children: [
                _header(),
                const SizedBox(height: 8),
                _sizeSelector(),
                const SizedBox(height: 10),
                Text("TIME: $seconds s    BEST: ${bestTimes[size] ?? 0} s",
                  style: GoogleFonts.pressStart2p(fontSize: 9, color: Colors.white)),
                const SizedBox(height: 6),
                Text("PLACED: $placedCount / $size",
                  style: GoogleFonts.pressStart2p(fontSize: 9, color: Colors.cyanAccent)),
                const Spacer(),
                _board(boardSize),
                const Spacer(),
                _controls(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        IconButton(icon: const Icon(Icons.arrow_back, color: Colors.yellowAccent), onPressed: () => Navigator.pop(context)),
        const Spacer(),
        Text(solving ? "SYSTEM COMPUTING…" : "N-QUEENS", 
          style: GoogleFonts.pressStart2p(fontSize: 12, color: Colors.yellowAccent)),
        const Spacer(),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _sizeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [4, 6, 8, 10, 12].map((s) {
        bool selected = size == s;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: GestureDetector(
            onTap: () { if (!solving) { size = s; _initializeBoard(); } },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.yellowAccent, width: 2),
                color: selected ? Colors.yellowAccent : Colors.black.withOpacity(0.6),
                boxShadow: selected ? [BoxShadow(color: Colors.yellowAccent.withOpacity(0.5), blurRadius: 10)] : [],
              ),
              child: Text("$s", style: GoogleFonts.pressStart2p(fontSize: 9, color: selected ? Colors.black : Colors.white)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _board(double boardSize) {
    return Container(
      width: boardSize,
      height: boardSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.yellowAccent, width: 2.5),
        boxShadow: [BoxShadow(color: Colors.yellowAccent.withOpacity(0.2), blurRadius: 15)],
      ),
      child: Container(
        color: Colors.black.withOpacity(0.85),
        child: Column(
          children: List.generate(size, (row) {
            return Expanded(
              child: Row(
                children: List.generate(size, (col) {
                  bool hasQueen = queens[col] == row;
                  bool attacked = _isAttacked(row, col);
                  bool isHint = (hintRow == row && hintCol == col);

                  // Tile is red if it's currently occupied by a queen that is in conflict
                  // Tile is cyan if it is simply under threat from a queen (including column threat)
                  Color tileColor = isHint 
                      ? Colors.yellowAccent 
                      : (attacked ? Colors.cyanAccent : Colors.cyanAccent);
                  
                  // If the queen herself is in a conflict position, we'll keep your red hint logic
                  bool isDangerousQueen = hasQueen && !_isSafe(row, col);

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _placeQueen(row, col),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isHint 
                                ? Colors.yellowAccent 
                                : (isDangerousQueen 
                                    ? Colors.redAccent 
                                    : (attacked ? Colors.cyanAccent.withOpacity(0.8) : Colors.cyanAccent.withOpacity(0.4))),
                            width: isHint ? 2.5 : 1.5,
                          ),
                          boxShadow: isHint || attacked || isDangerousQueen ? [
                            BoxShadow(
                                color: isHint ? Colors.yellowAccent.withOpacity(0.3) : (isDangerousQueen ? Colors.redAccent.withOpacity(0.3) : Colors.cyanAccent.withOpacity(0.3)), 
                                blurRadius: 8, 
                                spreadRadius: 1)
                          ] : [],
                        ),
                        child: Center(
                          child: hasQueen 
                            ? const Text("👑", style: TextStyle(fontSize: 20)) 
                            : (isHint ? const Icon(Icons.lightbulb_outline, color: Colors.yellowAccent, size: 16) : null),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _controls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _btn("RESET", _initializeBoard),
        const SizedBox(width: 15),
        _btn("HINT", _getHint),
        const SizedBox(width: 15),
        _btn("AI SOLVE", _startAI),
      ],
    );
  }

  Widget _btn(String text, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        side: const BorderSide(color: Colors.yellowAccent, width: 1.5),
        elevation: 5,
        shadowColor: Colors.yellowAccent.withOpacity(0.4),
      ),
      child: Text(text, style: GoogleFonts.pressStart2p(fontSize: 9, color: Colors.yellowAccent)),
    );
  }
}