/// 資源路徑常數類
class PathConstants {
  PathConstants._();
  
  // 音效檔案路徑
  static const String correctSoundPath = 'audio/effects/correct.mp3';
  static const String incorrectSoundPath = 'audio/effects/incorrect.mp3';
  
  // 預設圖片路徑
  static const String bookPlaceholderPath = 'assets/images/book_placeholder.jpg';
  static const String logoPath = 'assets/images/ESL Logo.png';
  
  // 正則表達式模式
  static const String bookDataPattern = r'assets/Book_data/(.+)_book_data\.json';
  static const String pageImagePattern = r'(.+)_(\d{2})-(\d{2})\.jpg';
} 