import 'package:flutter/foundation.dart';
import 'audio_service.dart';
import 'web_safe_audio_service.dart';

/// 音頻服務工廠，根據平台選擇合適的音頻服務實現
class AudioServiceFactory {
  // 單例模式
  static final AudioServiceFactory _instance = AudioServiceFactory._internal();

  factory AudioServiceFactory() {
    return _instance;
  }

  AudioServiceFactory._internal();

  // 根據平台獲取適合的音頻服務
  dynamic getAudioService() {
    if (kIsWeb) {
      print('使用Web安全音頻服務');
      return WebSafeAudioService();
    } else {
      print('使用標準音頻服務');
      return ImprovedAudioService();
    }
  }
}
