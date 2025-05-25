import 'dart:convert';
import 'package:flutter/services.dart';
import '../constants/book_constants.dart';

class VocabularyItem {
  final String word;
  final String translation;
  final String category;
  final String? imageFile;
  bool mastered;

  VocabularyItem({
    required this.word,
    required this.translation,
    required this.category,
    this.imageFile,
    this.mastered = false,
  });

  factory VocabularyItem.fromJson(Map<String, dynamic> json) {
    return VocabularyItem(
      word: json['Text'] ?? json['word'] ?? '',
      translation: json['中文翻譯'] ?? json['translation'] ?? '',
      category: json['Category'] ?? json['category'] ?? 'Word',
      imageFile: json['Image'],
      mastered: json['mastered'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'translation': translation,
      'category': category,
      'imageFile': imageFile,
      'mastered': mastered,
    };
  }
}

class VocabularyService {
  // 單例模式
  static final VocabularyService _instance = VocabularyService._internal();
  
  factory VocabularyService() {
    return _instance;
  }
  
  VocabularyService._internal();
  
  // 獲取指定書籍的詞彙
  Future<List<VocabularyItem>> getVocabularyForBook(String bookId) async {
    try {
      // 使用常數路徑
      final String jsonString = await rootBundle.loadString(BookConstants.getVocabularyPath(bookId));
      final dynamic data = json.decode(jsonString);
      final List<VocabularyItem> items = [];
      if (data is List) {
        // 正確格式：直接是 List
        for (var item in data) {
          items.add(VocabularyItem.fromJson(item));
        }
      } else if (data is Map<String, dynamic> && data.containsKey('vocabulary')) {
        // 舊格式：包在 vocabulary 屬性下
        for (var item in data['vocabulary']) {
          items.add(VocabularyItem.fromJson(item));
        }
      } else {
        throw FormatException('無效的詞彙數據格式');
      }
      return items;
    } catch (e) {
      print('載入詞彙數據失敗: $e');
      // 返回模擬數據作為備用
      return _getMockVocabulary(bookId);
    }
  }
  
  // 模擬數據 - 移除硬編碼，改為動態生成
  List<VocabularyItem> _getMockVocabulary(String bookId) {
    // 驗證教材ID是否有效
    if (!BookConstants.isValidBookId(bookId)) {
      return [];
    }
    
    final List<VocabularyItem> mockItems = [];
    final series = BookConstants.getBookSeries(bookId);
    
    // 根據系列生成不同的模擬詞彙
    switch (series) {
      case 'V':
        mockItems.addAll(_generateVSeriesMockData(bookId));
        break;
      case 'P':
        mockItems.addAll(_generatePSeriesMockData(bookId));
        break;
      case 'T':
        mockItems.addAll(_generateTSeriesMockData(bookId));
        break;
    }
    
    return mockItems;
  }
  
  // 生成 V 系列模擬數據
  List<VocabularyItem> _generateVSeriesMockData(String bookId) {
    final baseWords = ['apple', 'banana', 'cat', 'dog', 'elephant', 'fish', 'giraffe', 'happy', 'jump', 'kite'];
    final baseTranslations = ['蘋果', '香蕉', '貓', '狗', '大象', '魚', '長頸鹿', '快樂的', '跳躍', '風箏'];
    
    return List.generate(baseWords.length, (index) => VocabularyItem(
      word: baseWords[index],
      translation: baseTranslations[index],
      category: index < 7 ? 'Noun' : (index == 7 ? 'Adjective' : 'Verb'),
      imageFile: '${BookConstants.getBookImagePath(bookId)}/images/${baseWords[index]}.jpg',
      mastered: false,
    ));
  }
  
  // 生成 P 系列模擬數據
  List<VocabularyItem> _generatePSeriesMockData(String bookId) {
    // P 系列專注於自然發音
    final phoneticWords = ['bat', 'cat', 'hat', 'mat', 'pat', 'rat', 'sat', 'vat'];
    final translations = ['蝙蝠', '貓', '帽子', '墊子', '輕拍', '老鼠', '坐', '大桶'];
    
    return List.generate(phoneticWords.length, (index) => VocabularyItem(
      word: phoneticWords[index],
      translation: translations[index],
      category: 'Phonics',
      imageFile: '${BookConstants.getBookImagePath(bookId)}/images/${phoneticWords[index]}.jpg',
      mastered: false,
    ));
  }
  
  // 生成 T 系列模擬數據
  List<VocabularyItem> _generateTSeriesMockData(String bookId) {
    // T 系列專注於生活對話
    final conversationWords = ['hello', 'goodbye', 'please', 'thank you', 'excuse me', 'sorry'];
    final translations = ['你好', '再見', '請', '謝謝', '不好意思', '對不起'];
    
    return List.generate(conversationWords.length, (index) => VocabularyItem(
      word: conversationWords[index],
      translation: translations[index],
      category: 'Conversation',
      imageFile: '${BookConstants.getBookImagePath(bookId)}/images/${conversationWords[index]}.jpg',
      mastered: false,
    ));
  }
  
  // 獲取用戶的學習建議詞彙
  Future<List<VocabularyItem>> getRecommendedVocabulary(String userId, String bookId) async {
    // 實際應用中應根據用戶學習歷史和進度智能推薦
    // 這裡簡單返回一些未掌握的詞彙
    final allWords = await getVocabularyForBook(bookId);
    
    // 模擬: 隨機標記一些單字為已掌握
    for (var i = 0; i < allWords.length; i += 3) {
      if (i < allWords.length) {
        allWords[i].mastered = true;
      }
    }
    
    // 返回未掌握的單字
    return allWords.where((word) => !word.mastered).toList();
  }
}