import 'package:flutter/foundation.dart';
import '../speech_service.dart';
import 'web_safe_speech_service.dart';

/// 語音服務工廠，根據平台選擇合適的語音服務實現
class SpeechServiceFactory {
  // 單例模式
  static final SpeechServiceFactory _instance =
      SpeechServiceFactory._internal();

  factory SpeechServiceFactory() {
    return _instance;
  }

  SpeechServiceFactory._internal();

  // 根據平台獲取適合的語音服務
  dynamic getSpeechService() {
    if (kIsWeb) {
      print('使用Web安全語音服務');
      return WebSafeSpeechService();
    } else {
      print('使用標準語音服務');
      return SpeechService();
    }
  }
}
