import '../constants/book_constants.dart';

class AppConfig {
  // 版本設定
  static const List<String> bookVersions = BookConstants.enabledBooks;
  static String currentVersion = BookConstants.defaultBookId; // 使用常數
  static String currentLanguage = 'en'; // 預設語言

  // 資源路徑 - 使用 BookConstants 的方法
  static String get booksPath => BookConstants.getBookImagePath(currentVersion);
  static String get enAudioPath => BookConstants.getEnglishAudioPath(currentVersion);
  static String get zhAudioPath => BookConstants.getChineseAudioPath(currentVersion);
  static String get bookDataPath => BookConstants.getBookDataPath(currentVersion);

  // 圖片設置
  static const double defaultImageWidth = 2400.0;
  static const double defaultImageHeight = 1800.0;

  // 音頻設置
  static const int audioBitRate = 128000;
  static const int audioSampleRate = 44100;

  // UI 設置
  static const double clickableAreaBorderWidth = 1.0;
  static const double clickableAreaOpacity = 0.1;

  // 分類
  static const List<String> categories = ['全文', '段落句子', '單字'];
}
