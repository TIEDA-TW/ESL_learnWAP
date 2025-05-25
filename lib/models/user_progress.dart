class UserProgress {
  final String userId;
  final Map<String, BookProgress> bookProgress;
  
  UserProgress({
    required this.userId,
    required this.bookProgress,
  });
  
  factory UserProgress.initial(String userId) {
    return UserProgress(
      userId: userId,
      bookProgress: {},
    );
  }
  
  // 更新書籍進度
  UserProgress updateBookProgress(String bookId, BookProgress progress) {
    final updatedProgress = Map<String, BookProgress>.from(bookProgress);
    updatedProgress[bookId] = progress;
    
    return UserProgress(
      userId: userId,
      bookProgress: updatedProgress,
    );
  }
  
  // 從JSON創建實例
  factory UserProgress.fromJson(Map<String, dynamic> json) {
    final Map<String, BookProgress> progressMap = {};
    
    if (json['bookProgress'] != null) {
      (json['bookProgress'] as Map<String, dynamic>).forEach((key, value) {
        progressMap[key] = BookProgress.fromJson(value);
      });
    }
    
    return UserProgress(
      userId: json['userId'] ?? '',
      bookProgress: progressMap,
    );
  }
  
  // 轉換為JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> progressJson = {};
    bookProgress.forEach((key, value) {
      progressJson[key] = value.toJson();
    });
    
    return {
      'userId': userId,
      'bookProgress': progressJson,
    };
  }
}

class BookProgress {
  final String bookId;
  final int lastPageRead;
  final List<String> completedWords;
  final List<String> masteredWords; // 精通的單字（發音良好）
  final Map<String, int> gameScores; // 遊戲得分
  
  BookProgress({
    required this.bookId,
    required this.lastPageRead,
    required this.completedWords,
    required this.masteredWords,
    required this.gameScores,
  });
  
  factory BookProgress.initial(String bookId) {
    return BookProgress(
      bookId: bookId,
      lastPageRead: 0,
      completedWords: [],
      masteredWords: [],
      gameScores: {},
    );
  }
  
  // 更新最後閱讀頁面
  BookProgress updateLastPage(int page) {
    return BookProgress(
      bookId: bookId,
      lastPageRead: page,
      completedWords: completedWords,
      masteredWords: masteredWords,
      gameScores: gameScores,
    );
  }
  
  // 添加已完成單字
  BookProgress addCompletedWord(String word) {
    final updatedWords = List<String>.from(completedWords);
    if (!updatedWords.contains(word)) {
      updatedWords.add(word);
    }
    
    return BookProgress(
      bookId: bookId,
      lastPageRead: lastPageRead,
      completedWords: updatedWords,
      masteredWords: masteredWords,
      gameScores: gameScores,
    );
  }
  
  // 添加精通單字
  BookProgress addMasteredWord(String word) {
    final updatedMasteredWords = List<String>.from(masteredWords);
    if (!updatedMasteredWords.contains(word)) {
      updatedMasteredWords.add(word);
    }
    
    return BookProgress(
      bookId: bookId,
      lastPageRead: lastPageRead,
      completedWords: completedWords,
      masteredWords: updatedMasteredWords,
      gameScores: gameScores,
    );
  }

  // 移除精通單字
  BookProgress removeMasteredWord(String word) {
    final updatedMasteredWords = List<String>.from(masteredWords);
    updatedMasteredWords.remove(word);

    return BookProgress(
      bookId: bookId,
      lastPageRead: lastPageRead,
      completedWords: completedWords,
      masteredWords: updatedMasteredWords,
      gameScores: gameScores,
    );
  }

  
  // 更新遊戲得分
  BookProgress updateGameScore(String gameId, int score) {
    final updatedScores = Map<String, int>.from(gameScores);
    updatedScores[gameId] = score;
    
    return BookProgress(
      bookId: bookId,
      lastPageRead: lastPageRead,
      completedWords: completedWords,
      masteredWords: masteredWords,
      gameScores: updatedScores,
    );
  }
  
  // 從JSON創建實例
  factory BookProgress.fromJson(Map<String, dynamic> json) {
    return BookProgress(
      bookId: json['bookId'] ?? '',
      lastPageRead: json['lastPageRead'] ?? 0,
      completedWords: json['completedWords'] != null
          ? List<String>.from(json['completedWords'])
          : [],
      masteredWords: json['masteredWords'] != null
          ? List<String>.from(json['masteredWords'])
          : [],
      gameScores: json['gameScores'] != null
          ? Map<String, int>.from(json['gameScores'])
          : {},
    );
  }
  
  // 轉換為JSON
  Map<String, dynamic> toJson() {
    return {
      'bookId': bookId,
      'lastPageRead': lastPageRead,
      'completedWords': completedWords,
      'masteredWords': masteredWords,
      'gameScores': gameScores,
    };
  }
}