# MindMaze

MindMaze is a mobile puzzle application developed using Flutter that focuses on classical logical challenges and algorithmic problem solving. The project integrates multiple well known puzzles into a unified interactive environment while maintaining a visually distinctive neon arcade style user interface.

The primary objective of this application is to demonstrate the practical implementation of several fundamental computer science concepts including search algorithms, backtracking techniques, and state space exploration within a mobile application. Each puzzle is designed to allow users to interactively solve the problem themselves while also providing algorithmic solvers that demonstrate the underlying computational logic.

MindMaze emphasizes both educational and entertainment value. By combining algorithm visualization with user driven gameplay, the application allows players to observe how artificial intelligence techniques can efficiently solve complex logical problems.

---

# Project Objectives

The core goals of this project include the following:

• Implementation of classical algorithmic puzzles within a mobile application  
• Visualization of algorithmic problem solving techniques  
• Integration of artificial intelligence algorithms into interactive gameplay  
• Development of a structured Flutter based mobile application architecture  
• Exploration of user interface design inspired by retro arcade aesthetics  

The project demonstrates how theoretical algorithmic concepts can be translated into practical, user friendly applications.

---

# Games Included in MindMaze

## 1. Eight Puzzle

The Eight Puzzle is a classical sliding tile puzzle consisting of a 3×3 grid containing numbered tiles and a single empty space. The objective of the puzzle is to rearrange the tiles into the correct numerical order by sliding adjacent tiles into the empty space.

### Features

• Interactive tile sliding mechanism  
• Real time move counter and timer tracking  
• Artificial Intelligence solver implemented using the A* search algorithm  
• Manhattan distance heuristic for optimal path estimation  
• Visual animation of algorithmic solution steps  

The A* algorithm ensures that the puzzle is solved optimally by evaluating both the cost of the path taken and the heuristic estimate of the remaining distance to the goal state.

---

## 2. N-Queens Problem

The N-Queens puzzle is a classical combinatorial problem in which the objective is to place N queens on an N×N chessboard in such a way that no two queens threaten each other. This means that no two queens may share the same row, column, or diagonal.

### Features

• Multiple board sizes including 4×4, 6×6, 8×8, 10×10, and 12×12 configurations  
• Interactive queen placement using tap based input  
• Real time conflict detection highlighting attacking positions  
• Backtracking based AI solver  
• Performance tracking using timers and best completion records  

The backtracking algorithm systematically explores all possible board configurations until a valid solution is identified.

---

## 3. Water Jug Puzzle

The Water Jug problem is a classical problem in state space search where two containers with fixed capacities must be used to measure an exact quantity of water.

Players can perform operations such as filling, emptying, and pouring water between containers in order to achieve the target volume.

### Features

• Adjustable jug capacities and customizable target volume  
• Interactive water transfer mechanics  
• Real time move tracking  
• Algorithmic solver implemented using Breadth First Search (BFS)  
• Step by step visualization of the optimal solution path  

Breadth First Search guarantees the discovery of the minimum sequence of operations required to reach the target configuration.

---

# Key Application Features

• Neon themed arcade inspired graphical interface  
• Interactive gameplay mechanics for multiple puzzle types  
• Artificial Intelligence based puzzle solvers  
• Algorithm visualization through animated state transitions  
• Timer based performance tracking  
• Move counters and optimal solution comparison  
• Confetti based victory animation system  
• Modular Flutter architecture supporting multiple game modules  

The application architecture was designed to allow additional puzzles to be incorporated easily in future versions.

---

# Technologies Used

The project is developed using the following technologies and tools:

Flutter  
Dart Programming Language  
Material UI Framework  
Artificial Intelligence Search Algorithms  
State Space Search Techniques  

Algorithmic implementations include:

A* Search Algorithm  
Breadth First Search (BFS)  
Backtracking Algorithm  

These algorithms were selected because they represent fundamental strategies commonly used in artificial intelligence and optimization problems.

---
# Project Architecture

The application follows a modular structure where each puzzle is implemented as an independent feature module within the Flutter project.

```
lib/
 ├── features/
 │    ├── home/
 │    │    ├── home_page.dart
 │    │    ├── eight_puzzle.dart
 │    │    ├── n_queen_game.dart
 │    │    └── water_jug_game.dart
 │    └── splash/
 │         └── splash_screen.dart
 └── main.dart
```

This architecture improves maintainability and allows future extensions without affecting existing components.

---

# Installation

To run the project locally, clone the repository and install the required dependencies.

This architecture improves maintainability and allows future extensions without affecting existing components.

git clone https://github.com/naffss-eng/MindMaze.git
```
cd MindMaze
flutter pub get
flutter run
```

Ensure that Flutter is properly installed and configured on the development machine.

---

# APK Download

The compiled Android application can be downloaded from the project release page.

Direct download link:

https://github.com/naffss-eng/MindMaze/releases/download/v1.0/app-release.apk

The APK file can be installed directly on Android devices that allow installation from external sources.

---

# Author

Nafisa Hasan  
GitHub Profile: https://github.com/naffss-eng

---

# Conclusion

MindMaze demonstrates the practical application of algorithmic problem solving within an interactive mobile environment. By combining educational algorithm visualization with engaging gameplay, the project illustrates how classical computer science concepts can be integrated into modern mobile software development.

The project also highlights the flexibility of the Flutter framework for building visually rich, modular, and algorithmically driven mobile applications.
