import 'dart:math';

enum CTDifficulty { normal, hard, veryHard }

extension CTDifficultyX on CTDifficulty {
  String get label {
    switch (this) {
      case CTDifficulty.normal:   return 'Normal';
      case CTDifficulty.hard:     return 'Hard';
      case CTDifficulty.veryHard: return 'Very Hard';
    }
  }

  String get key {
    switch (this) {
      case CTDifficulty.normal:   return 'normal';
      case CTDifficulty.hard:     return 'hard';
      case CTDifficulty.veryHard: return 'veryHard';
    }
  }

  // Grid size
  int get gridSize {
    switch (this) {
      case CTDifficulty.normal:   return 4; // 4×4 = 16 tiles
      case CTDifficulty.hard:     return 5; // 5×5 = 25 tiles
      case CTDifficulty.veryHard: return 6; // 6×6 = 36 tiles
    }
  }

  // How many yellow tiles — multiple per round
  int get yellowCount {
    switch (this) {
      case CTDifficulty.normal:   return 3; // 3 yellow in 4×4
      case CTDifficulty.hard:     return 5; // 5 yellow in 5×5
      case CTDifficulty.veryHard: return 7; // 7 yellow in 6×6
    }
  }

  // Flame count for difficulty indicator
  int get flameCount {
    switch (this) {
      case CTDifficulty.normal:   return 2;
      case CTDifficulty.hard:     return 3;
      case CTDifficulty.veryHard: return 5;
    }
  }

  // How long to show yellow tiles in preview (ms)
  int get showDurationMs {
    switch (this) {
      case CTDifficulty.normal:   return 2500;
      case CTDifficulty.hard:     return 2000;
      case CTDifficulty.veryHard: return 1500;
    }
  }

  static CTDifficulty fromKey(String key) {
    switch (key) {
      case 'hard':     return CTDifficulty.hard;
      case 'veryHard': return CTDifficulty.veryHard;
      default:         return CTDifficulty.normal;
    }
  }
}

class ColourTilesConfig {
  final CTDifficulty difficulty;
  final int          questionCount;

  const ColourTilesConfig({
    this.difficulty    = CTDifficulty.normal,
    this.questionCount = 3,
  });

  Map<String, dynamic> toJson() => {
    'difficulty':    difficulty.key,
    'questionCount': questionCount,
  };

  factory ColourTilesConfig.fromJson(Map<String, dynamic> json) =>
      ColourTilesConfig(
        difficulty:    CTDifficultyX.fromKey(
            json['difficulty'] as String? ?? 'normal'),
        questionCount: json['questionCount'] as int? ?? 3,
      );

  ColourTilesConfig copyWith({
    CTDifficulty? difficulty,
    int? questionCount,
  }) =>
      ColourTilesConfig(
        difficulty:    difficulty    ?? this.difficulty,
        questionCount: questionCount ?? this.questionCount,
      );
}

class ColourTilesPuzzle {
  final int        gridSize;
  final List<int>  yellowIndices; // ALL yellow tile positions

  const ColourTilesPuzzle({
    required this.gridSize,
    required this.yellowIndices,
  });

  // Generate puzzle with MULTIPLE random yellow tiles
  factory ColourTilesPuzzle.generate(CTDifficulty difficulty) {
    final rng     = Random();
    final total   = difficulty.gridSize * difficulty.gridSize;
    final count   = difficulty.yellowCount;
    final indices = <int>{};
    while (indices.length < count) {
      indices.add(rng.nextInt(total));
    }
    return ColourTilesPuzzle(
      gridSize:      difficulty.gridSize,
      yellowIndices: indices.toList(),
    );
  }

  int get totalTiles => gridSize * gridSize;

  bool isYellow(int index) => yellowIndices.contains(index);

  // Puzzle solved when user has tapped ALL yellow tiles
  bool isSolvedWith(Set<int> tapped) {
    return yellowIndices.every((i) => tapped.contains(i));
  }
}
