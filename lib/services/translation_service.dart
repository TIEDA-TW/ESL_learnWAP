import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:io';
import 'error_handler.dart';
import '../models/book_models_fixed.dart';
import 'storage_service.dart';

class TranslationService {
  Map<String, String> _translationData = {};
  bool _isInitialized = false;
  final StorageService _storageService = StorageService();
  
  // 單例模式
  static final TranslationService _instance = TranslationService._internal();
  
  factory TranslationService() {
    return _instance;
  }
  
  TranslationService._internal();
  
  // 檢查是否初始化
  bool get isInitialized => _isInitialized;
  
  // 初始化翻譯數據
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }
    
    try {
      // 載入所有書籍數據來獲取翻譯
      await _loadTranslationsFromBookData();
      
      _isInitialized = true;
      print('翻譯服務初始化成功，載入了 ${_translationData.length} 個翻譯項目');
    } catch (e) {
      ErrorHandler.logError('初始化翻譯服務失敗: $e');
      // 創建一個備用翻譯數據以避免空指針
      await _createFallbackTranslation();
    }
  }
  
  // 從書籍 JSON 文件加載翻譯數據
  Future<void> _loadTranslationsFromBookData() async {
    try {
      // 取得所有書籍數據文件的路徑
      List<String> bookDataPaths = await _getBookDataPaths();
      
      // 遍歷每個書籍數據文件
      for (String dataPath in bookDataPaths) {
        try {
          // 直接讀取 JSON 文件
          final String jsonString = await rootBundle.loadString(dataPath);
          final List<dynamic> bookData = json.decode(jsonString);
          
          // 提取翻譯數據
          for (var item in bookData) {
            if (item is Map<String, dynamic> && 
                item.containsKey('Text') && 
                item.containsKey('中文翻譯')) {
              
              final String englishText = item['Text'];
              final String chineseText = item['中文翻譯'];
              
              if (englishText.isNotEmpty && chineseText.isNotEmpty) {
                _translationData[englishText] = chineseText;
              }
            }
          }
        } catch (e) {
          print('載入翻譯數據從 $dataPath 失敗: $e');
          // 繼續處理下一個文件
        }
      }
      
      print('從書籍數據中成功載入 ${_translationData.length} 個翻譯項目');
    } catch (e) {
      ErrorHandler.logError('從書籍數據加載翻譯失敗: $e');
      throw Exception('無法從書籍數據加載翻譯: $e');
    }
  }
  
  // 獲取所有書籍數據文件的路徑
  Future<List<String>> _getBookDataPaths() async {
    try {
      final List<String> bookDataPaths = [];
      const bookDataDir = 'assets/Book_data';
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final keys = manifest.listAssets();
      final dataFilePaths = keys.where((String key) {
        return key.startsWith(bookDataDir) && key.endsWith('.json');
      }).toList();
      bookDataPaths.addAll(dataFilePaths);
      return bookDataPaths;
    } catch (e) {
      ErrorHandler.logError('獲取書籍數據路徑失敗: $e');
      return [];
    }
  }
  
  // 為指定書籍加載翻譯（用於翻譯模式）
  Future<Map<String, String>> loadTranslationsForBook(String bookDataPath) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      // 讀取特定書籍的JSON數據
      final String jsonString = await rootBundle.loadString(bookDataPath);
      final List<dynamic> bookData = json.decode(jsonString);
      
      // 臨時儲存本書翻譯
      final Map<String, String> bookTranslations = {};
      
      // 提取翻譯數據
      for (var item in bookData) {
        if (item is Map<String, dynamic> && 
            item.containsKey('Text') && 
            item.containsKey('中文翻譯')) {
          
          final String englishText = item['Text'];
          final String chineseText = item['中文翻譯'];
          
          if (englishText.isNotEmpty && chineseText.isNotEmpty) {
            bookTranslations[englishText] = chineseText;
            
            // 同時更新全局翻譯數據
            _translationData[englishText] = chineseText;
          }
        }
      }
      
      print('為書籍 $bookDataPath 載入了 ${bookTranslations.length} 個翻譯項目');
      return bookTranslations;
    } catch (e) {
      ErrorHandler.logError('為書籍 $bookDataPath 載入翻譯失敗: $e');
      return {};
    }
  }
  
  // 建立備用翻譯數據（用於測試或翻譯文件損壞時）
  Future<void> _createFallbackTranslation() async {
    try {
      _translationData = {
        'hello': '你好',
        'book': '書',
        'read': '閱讀',
        'listen': '聽',
        'speak': '說話',
        'apple': '蘋果',
        'banana': '香蕉',
        'cat': '貓',
        'dog': '狗',
        'house': '房子',
        'school': '學校',
        'teacher': '老師',
        'student': '學生',
        'friend': '朋友',
        'family': '家庭',
        'mother': '媽媽',
        'father': '爸爸',
        'sister': '姐妹',
        'brother': '兄弟',
        'car': '汽車',
        'bus': '公車',
        'train': '火車',
        'airplane': '飛機',
        'water': '水',
        'food': '食物',
        'play': '玩',
        'swim': '游泳',
        'run': '跑步',
        'walk': '走路',
        'jump': '跳',
        'sing': '唱歌',
        'dance': '跳舞',
        'write': '寫',
        'draw': '畫',
        'color': '顏色',
        'red': '紅色',
        'blue': '藍色',
        'green': '綠色',
        'yellow': '黃色',
        'black': '黑色',
        'white': '白色',
        'one': '一',
        'two': '二',
        'three': '三',
        'four': '四',
        'five': '五',
        'good': '好',
        'bad': '壞',
        'happy': '開心',
        'sad': '難過',
        'big': '大',
        'small': '小',
        'tall': '高',
        'short': '矮',
        'up': '上',
        'down': '下',
        'left': '左',
        'right': '右',
        'hot': '熱',
        'cold': '冷',
        'sunny': '晴天',
        'rainy': '雨天',
        'windy': '有風',
        'cloudy': '多雲',
        'snow': '雪',
      };
      
      print('已創建備用翻譯數據，共 ${_translationData.length} 個項目');
      _isInitialized = true;
    } catch (e) {
      ErrorHandler.logError('創建備用翻譯失敗: $e');
    }
  }
  
  // 獲取翻譯
  String translate(String text) {
    if (!_isInitialized) {
      print('警告: 翻譯服務尚未初始化，正在嘗試初始化');
      initialize();
      return text;
    }
    
    if (_translationData.isEmpty) {
      return text;
    }
    
    // 嘗試查找完整文本的翻譯
    if (_translationData.containsKey(text)) {
      return _translationData[text]!;
    }
    
    // 如果找不到完整翻譯，嘗試逐詞翻譯
    final words = text.split(' ');
    final translatedWords = words.map((word) {
      // 移除所有標點符號後尋找翻譯
      final cleanWord = word.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
      
      if (_translationData.containsKey(cleanWord)) {
        // 保留原始標點和大小寫
        final punctuation = word.replaceAll(RegExp(r'[\w\s]'), '');
        return _translationData[cleanWord]! + punctuation;
      }
      
      // 嘗試尋找單詞的單數形式（移除尾部 s）
      if (cleanWord.endsWith('s')) {
        final singular = cleanWord.substring(0, cleanWord.length - 1);
        if (_translationData.containsKey(singular)) {
          // 保留原始標點和大小寫
          final punctuation = word.replaceAll(RegExp(r'[\w\s]'), '');
          return _translationData[singular]! + punctuation;
        }
      }
      
      // 如果找不到翻譯，保留原始單詞
      return word;
    }).toList();
    
    return translatedWords.join(' ');
  }
  
  // 批量翻譯
  Map<String, String> translateBatch(List<String> texts) {
    final Map<String, String> results = {};
    
    for (var text in texts) {
      results[text] = translate(text);
    }
    
    return results;
  }
  
  // 添加或更新翻譯
  void addTranslation(String key, String value) {
    if (!_isInitialized) {
      initialize();
    }
    
    _translationData[key] = value;
  }
  
  // 添加多個翻譯
  void addTranslations(Map<String, String> translations) {
    if (!_isInitialized) {
      initialize();
    }
    
    _translationData.addAll(translations);
  }
}