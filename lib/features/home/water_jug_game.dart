import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WaterJugGame extends StatefulWidget {
  const WaterJugGame({super.key});

  @override
  State<WaterJugGame> createState() => _WaterJugGameState();
}

class _WaterJugGameState extends State<WaterJugGame> {
  int capA = 5;
  int capB = 3;
  int goal = 4;
  int curA = 0;
  int curB = 0;
  int moves = 0;
  int seconds = 0;
  bool isGameOver = false;
  bool isSolving = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    timer?.cancel();
    seconds = 0;
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!isGameOver && mounted) setState(() => seconds++);
    });
  }

  int _getGCD(int a, int b) {
    while (b != 0) {
      var t = b;
      b = a % b;
      a = t;
    }
    return a;
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.9),
          shape: RoundedRectangleBorder(
              side: const BorderSide(color: Colors.cyanAccent),
              borderRadius: BorderRadius.circular(10)),
          title: Text("CONFIG",
              style: GoogleFonts.pressStart2p(color: Colors.pinkAccent, fontSize: 14)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDropdown("CAP A", capA, (v) => setDialogState(() => capA = v!)),
              _buildDropdown("CAP B", capB, (v) => setDialogState(() => capB = v!)),
              _buildDropdown("GOAL", goal, (v) => setDialogState(() => goal = v!)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                int commonDivisor = _getGCD(capA, capB);
                if (goal % commonDivisor != 0 || goal > max(capA, capB)) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    backgroundColor: Colors.redAccent,
                    content: Text(
                        "IMPOSSIBLE: Multiple of $commonDivisor & ≤ max cap",
                        style: GoogleFonts.pressStart2p(fontSize: 7)),
                  ));
                } else {
                  setState(() {
                    curA = 0; curB = 0; moves = 0;
                    isGameOver = false; isSolving = false; _startTimer();
                  });
                  Navigator.pop(context);
                }
              },
              child: Text("APPLY",
                  style: GoogleFonts.pressStart2p(color: Colors.cyanAccent, fontSize: 10)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, int val, ValueChanged<int?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.pressStart2p(color: Colors.white, fontSize: 8)),
          DropdownButton<int>(
            value: val,
            dropdownColor: Colors.grey[900],
            style: GoogleFonts.pressStart2p(color: Colors.cyanAccent, fontSize: 10),
            items: List.generate(15, (i) => i + 1)
                .map((i) => DropdownMenuItem(value: i, child: Text("$i L")))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  List<List<int>> _solveBFS(int startA, int startB) {
    Queue<List<dynamic>> queue = Queue();
    queue.add([startA, startB, <List<int>>[]]);
    Set<String> visited = {"$startA,$startB"};

    while (queue.isNotEmpty) {
      var current = queue.removeFirst();
      int a = current[0];
      int b = current[1];
      List<List<int>> history = List.from(current[2]);
      history.add([a, b]);

      if (a == goal || b == goal) return history;

      var nextStates = [
        [capA, b], [a, capB],
        [0, b], [a, 0],
        [a - min(a, capB - b), b + min(a, capB - b)],
        [a + min(b, capA - a), b - min(b, capA - a)],
      ];

      for (var state in nextStates) {
        String key = "${state[0]},${state[1]}";
        if (!visited.contains(key)) {
          visited.add(key);
          queue.add([state[0], state[1], history]);
        }
      }
    }
    return [];
  }

  void _showHint() {
    List<List<int>> path = _solveBFS(curA, curB);
    if (path.length > 1) {
      int nextA = path[1][0];
      int nextB = path[1][1];
      String action = "";
      if (nextA == capA && nextB == curB) action = "Fill Jug A";
      else if (nextB == capB && nextA == curA) action = "Fill Jug B";
      else if (nextA == 0 && nextB == curB) action = "Empty Jug A";
      else if (nextB == 0 && nextA == curA) action = "Empty Jug B";
      else if (nextA < curA) action = "Transfer A to B";
      else action = "Transfer B to A";

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.pinkAccent,
        content: Text("HINT: $action", style: GoogleFonts.pressStart2p(fontSize: 10)),
      ));
    }
  }

  void _runAiSolve() async {
    if (isSolving) return;
    List<List<int>> path = _solveBFS(curA, curB);
    if (path.isEmpty) return;

    setState(() => isSolving = true);
    for (int i = 1; i < path.length; i++) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() {
        curA = path[i][0];
        curB = path[i][1];
        moves++;
      });
    }
    _triggerWin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset("assets/images/water_jug_bg.jpg", fit: BoxFit.cover)),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 130), // Fixes title clipping
                _buildHUD(),
                const SizedBox(height: 20),
                Text("TARGET: $goal L", style: GoogleFonts.pressStart2p(color: Colors.white, fontSize: 22, shadows: [const Shadow(color: Colors.cyanAccent, blurRadius: 10)])),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _jugDisplay(curA, capA, "JUG A"),
                    _jugDisplay(curB, capB, "JUG B"),
                  ],
                ),
                const Spacer(),
                _buildControlPanel(),
              ],
            ),
          ),
          if (isGameOver) _buildWinOverlay(),
        ],
      ),
    );
  }

  Widget _jugDisplay(int cur, int cap, String label) {
    return Column(
      children: [
        Container(
          width: 100, height: 160,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            border: Border.all(color: cur == goal ? Colors.greenAccent : Colors.white, width: 3),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15)),
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: 160 * (cur / cap),
                width: double.infinity,
                color: (cur == goal ? Colors.greenAccent : Colors.cyanAccent).withOpacity(0.6),
              ),
              Center(child: Text("$cur/$cap", style: GoogleFonts.pressStart2p(color: Colors.white, fontSize: 12))),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(label, style: GoogleFonts.pressStart2p(color: Colors.cyanAccent, fontSize: 10)),
      ],
    );
  }

  Widget _buildHUD() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _pixelBtn("BACK", () => Navigator.pop(context), color: Colors.redAccent),
          _hudStat("TIME: $seconds", Colors.pinkAccent),
          _hudStat("MOVES: $moves", Colors.pinkAccent),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.lightbulb, color: Colors.yellow), onPressed: _showHint),
              IconButton(icon: const Icon(Icons.settings, color: Colors.cyanAccent), onPressed: _showSettings),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hudStat(String txt, Color borderCol) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.black, border: Border.all(color: borderCol)),
      child: Text(txt, style: GoogleFonts.pressStart2p(color: Colors.white, fontSize: 8)),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(15),
      color: Colors.black.withOpacity(0.8),
      child: Wrap(
        spacing: 10, runSpacing: 10, alignment: WrapAlignment.center,
        children: [
          _pixelBtn("FILL A", () => _update(() => curA = capA)),
          _pixelBtn("FILL B", () => _update(() => curB = capB)),
          _pixelBtn("EMPTY A", () => _update(() => curA = 0)),
          _pixelBtn("EMPTY B", () => _update(() => curB = 0)),
          _pixelBtn("A ➔ B", () => _transfer(true)),
          _pixelBtn("B ➔ A", () => _transfer(false)),
          _pixelBtn("AI SOLVE", _runAiSolve, color: Colors.pinkAccent),
          _pixelBtn("RESET", () => setState(() { curA = 0; curB = 0; moves = 0; isGameOver = false; isSolving = false; _startTimer(); })),
        ],
      ),
    );
  }

  void _update(VoidCallback action) {
    if (isGameOver || isSolving) return;
    setState(() {
      action();
      moves++;
      if (curA == goal || curB == goal) {
        _triggerWin();
      }
    });
  }

  void _triggerWin() async {
    timer?.cancel();
    await Future.delayed(const Duration(seconds: 1)); // 1 sec delay
    if (mounted) setState(() {
      isGameOver = true;
      isSolving = false;
    });
  }

  void _transfer(bool aToB) {
    _update(() {
      int amt = aToB ? min(curA, capB - curB) : min(curB, capA - curA);
      if (aToB) { curA -= amt; curB += amt; } else { curB -= amt; curA += amt; }
    });
  }

  Widget _pixelBtn(String txt, VoidCallback tap, {Color color = Colors.cyanAccent}) {
    return ElevatedButton(
      onPressed: tap,
      style: ElevatedButton.styleFrom(backgroundColor: Colors.black, side: BorderSide(color: color)),
      child: Text(txt, style: GoogleFonts.pressStart2p(color: color, fontSize: 8)),
    );
  }

  Widget _buildWinOverlay() {
    // Rank Logic restored
    int minMoves = _solveBFS(0, 0).length;
    String rank = moves <= minMoves + 2 ? "S" : moves <= minMoves + 5 ? "A" : "B";
    
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          width: 300,
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: Colors.greenAccent, width: 4),
            boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.5), blurRadius: 20)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("MISSION SUCCESS", style: GoogleFonts.pressStart2p(color: Colors.greenAccent, fontSize: 14)),
              const Divider(color: Colors.greenAccent, thickness: 2, height: 30),
              _winRow("TIME TAKEN", "$seconds SEC"),
              _winRow("TOTAL MOVES", "$moves"),
              _winRow("RANK", rank, rankColor: Colors.yellowAccent),
              const SizedBox(height: 30),
              _pixelBtn("CONTINUE", () => setState(() { curA = 0; curB = 0; moves = 0; isGameOver = false; isSolving = false; _startTimer(); }), color: Colors.greenAccent),
              const SizedBox(height: 10),
              _pixelBtn("BACK TO ARCADE", () => Navigator.pop(context), color: Colors.redAccent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _winRow(String label, String value, {Color rankColor = Colors.white}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.pressStart2p(color: Colors.white, fontSize: 8)),
          Text(value, style: GoogleFonts.pressStart2p(color: rankColor, fontSize: 10)),
        ],
      ),
    );
  }
}