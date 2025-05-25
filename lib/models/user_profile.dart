
import 'package:collection/collection.dart';

class UserProfile {
  Map<String, double> wordMasteryScores = {};

  double masteryScore(String word) {
    return wordMasteryScores[word] ?? 0;
  }

  void updateMasteryScore(String word, double score) {
    wordMasteryScores[word] = (wordMasteryScores[word] ?? 0) + score;
  }

  double get progressPercentage {
    if (wordMasteryScores.isEmpty) return 0;
    double totalScore = wordMasteryScores.values.sum;
    double maxScore = wordMasteryScores.length * 10;
    return totalScore / maxScore * 100;  
  }
}
