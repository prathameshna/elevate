import 'dart:math';

class MemoryMissionConfig {
  final int    questionCount;
  final String difficulty;

  const MemoryMissionConfig({
    this.questionCount = 3,
    this.difficulty    = 'normal',
  });

  int get tilesToMemorize {
    switch (difficulty) {
      case 'easy':   return 3;
      case 'normal': return 6;
      case 'hard':   return 9;
      case 'expert': return 13;
      default:       return 6;
    }
  }

  int get memorizeDurationMs {
    switch (difficulty) {
      case 'easy':   return 4000;
      case 'normal': return 3000;
      case 'hard':   return 2000;
      case 'expert': return 1500;
      default:       return 3000;
    }
  }

  int get flameCount {
    switch (difficulty) {
      case 'easy':   return 1;
      case 'normal': return 3;
      case 'hard':   return 4;
      case 'expert': return 5;
      default:       return 3;
    }
  }

  Map<String, dynamic> toJson() => {
    'questionCount': questionCount,
    'difficulty':    difficulty,
  };

  factory MemoryMissionConfig.fromJson(Map<String, dynamic> json) =>
      MemoryMissionConfig(
        questionCount: (json['questionCount'] as int?) ?? 3,
        difficulty:    (json['difficulty']    as String?) ?? 'normal',
      );

  MemoryMissionConfig copyWith({int? questionCount, String? difficulty}) =>
      MemoryMissionConfig(
        questionCount: questionCount ?? this.questionCount,
        difficulty:    difficulty    ?? this.difficulty,
      );
}

class MemoryQuestion {
  final List<int> highlightedIndices;

  const MemoryQuestion({required this.highlightedIndices});

  // Generates NEW random tiles every call — guaranteed different each question
  factory MemoryQuestion.generate(int count) {
    final rng     = Random();
    final indices = <int>{};
    while (indices.length < count) {
      indices.add(rng.nextInt(25));
    }
    return MemoryQuestion(highlightedIndices: indices.toList());
  }

  // Returns true only if tapped tiles exactly match highlighted tiles
  bool isCorrect(List<int> tapped) {
    if (tapped.length != highlightedIndices.length) return false;
    final a = Set<int>.from(tapped);
    final b = Set<int>.from(highlightedIndices);
    return a.containsAll(b) && b.containsAll(a);
  }
}
