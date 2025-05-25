import 'package:flutter/material.dart';

/// 教材管理常數類
class BookConstants {
  // 禁止實例化
  BookConstants._();

  /// 啟用的教材ID列表
  static const List<String> enabledBooks = [
    // V系列 (基礎教材)
    'V1', 'V2', 'V3', 'V4', 'V5', 'V6', 'V7', 'V8', 'V9',
    
    // P系列 (入門教材) - 
    'P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7', 'P8', 'P9',
    
    // T系列 (主題教材) - 
    'T1-1', 'T1-2', 'T1-3', 'T1-4', 'T1-5',
    'T2-1', 'T2-2', 'T2-3', 'T2-4', 'T2-5',
    'T3-1', 'T3-2', 'T3-3', 'T3-4', 'T3-5'
  ];
  
  /// 預設教材ID
  static String get defaultBookId => enabledBooks.isNotEmpty ? enabledBooks.first : 'V1';
  
  /// 各系列教材的名稱映射
  static const Map<String, String> seriesNames = {
    'V': '基礎字彙',
    'P': '自然發音',
    'T': '生活對話',
  };
  
  /// 各系列的顏色
  static const Map<String, Color> seriesColors = {
    'V': Colors.blue,
    'P': Colors.green,
    'T': Colors.orange,
  };

  // === 資源路徑常數 ===
  
  /// 基礎資源路徑
  static const String assetsPath = 'assets';
  static const String bookDataPath = '$assetsPath/Book_data';
  static const String booksPath = '$assetsPath/Books';
  static const String audioPath = '$assetsPath/audio';
  
  /// 音檔路徑
  static const String enAudioPath = '$audioPath/en';
  static const String zhAudioPath = '$audioPath/zh';
  
  /// 檔案命名規則
  static const String bookDataFilePattern = '{bookId}_book_data.json';
  static const String coverImagePattern = '{bookId}_00-00.jpg';
  static const String vocabularyFilePattern = '{bookId}_vocabulary.json';
  
  // === 路徑生成方法 ===
  
  /// 獲取教材數據檔案路徑
  static String getBookDataPath(String bookId) {
    return '$bookDataPath/${bookDataFilePattern.replaceAll('{bookId}', bookId)}';
  }
  
  /// 獲取教材圖片目錄路徑
  static String getBookImagePath(String bookId) {
    return '$booksPath/$bookId';
  }
  
  /// 獲取教材封面圖片路徑
  static String getBookCoverPath(String bookId) {
    return '${getBookImagePath(bookId)}/${coverImagePattern.replaceAll('{bookId}', bookId)}';
  }
  
  /// 獲取詞彙檔案路徑
  static String getVocabularyPath(String bookId) {
    return '$bookDataPath/${vocabularyFilePattern.replaceAll('{bookId}', bookId)}';
  }
  
  /// 獲取英文音檔路徑
  static String getEnglishAudioPath(String bookId) {
    return '$enAudioPath/$bookId';
  }
  
  /// 獲取中文音檔路徑
  static String getChineseAudioPath(String bookId) {
    return '$zhAudioPath/$bookId';
  }
  
  /// 獲取完整音檔路徑
  static String getAudioFilePath(String bookId, String audioFileName, {bool isChinese = false}) {
    final basePath = isChinese ? getChineseAudioPath(bookId) : getEnglishAudioPath(bookId);
    return '$basePath/$audioFileName';
  }

  // === 現有方法保持不變 ===
  
  /// 獲取特定系列的所有啟用教材
  static List<String> getEnabledSeriesBooks(String series) {
    return enabledBooks.where((id) => id.startsWith(series)).toList();
  }
  
  /// 獲取所有啟用的系列
  static List<String> get enabledSeries {
    final Set<String> series = {};
    for (final id in enabledBooks) {
      series.add(id.substring(0, 1));
    }
    return series.toList();
  }
  
  /// 獲取特定教材的顯示名稱
  static String getBookDisplayName(String bookId) {
    final series = bookId.substring(0, 1);
    final seriesName = seriesNames[series] ?? '教材';
    return '$seriesName $bookId';
  }
  
  /// 獲取特定教材的顏色
  static Color getBookColor(String bookId) {
    final series = bookId.substring(0, 1);
    return seriesColors[series] ?? Colors.grey;
  }
  
  // === 驗證方法 ===
  
  /// 驗證教材ID是否有效
  static bool isValidBookId(String bookId) {
    return enabledBooks.contains(bookId);
  }
  
  /// 獲取教材系列
  static String getBookSeries(String bookId) {
    return bookId.isNotEmpty ? bookId.substring(0, 1) : '';
  }
  
  /// 驗證系列是否有效
  static bool isValidSeries(String series) {
    return seriesNames.containsKey(series);
  }
} 