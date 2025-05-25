import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:js' as js;
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

class EnvService {
  static final EnvService _instance = EnvService._internal();
  factory EnvService() => _instance;
  EnvService._internal();

  // 檢查是否在 Web 平台上
  bool get isWeb => kIsWeb;

  // 從 window.flutterEnvironment 獲取值
  String? _getWebEnv(String key) {
    if (!isWeb) return null;
    
    try {
      // 檢查 window.flutterEnvironment 是否存在
      if (js.context.hasProperty('flutterEnvironment')) {
        final env = js.context['flutterEnvironment'];
        if (env != null && env.hasProperty(key)) {
          return env[key] as String?;
        }
      }
    } catch (e) {
      print('獲取 Web 環境變數失敗: $e');
    }
    return null;
  }

  Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
      print('成功載入 .env 檔案');
    } catch (e) {
      print('無法載入 .env 檔案: $e，將使用預設值');
    }

    if (isWeb) {
      print('在 Web 環境中，嘗試使用 window.flutterEnvironment');
      // 在這裡不需要做任何事情，因為我們會在每個 getter 方法中檢查 window.flutterEnvironment
    }
  }

  // 應用設定
  String get appName => _getWebEnv('APP_NAME') ?? dotenv.env['APP_NAME'] ?? '台灣兒童美語協會ESL美語教學軟體';
  String get appVersion => _getWebEnv('APP_VERSION') ?? dotenv.env['APP_VERSION'] ?? '1.0.0';

  // API 設定
  String get apiBaseUrl => _getWebEnv('API_BASE_URL') ?? dotenv.env['API_BASE_URL'] ?? '';
  int get apiTimeout => int.tryParse(_getWebEnv('API_TIMEOUT') ?? dotenv.env['API_TIMEOUT'] ?? '30000') ?? 30000;

  // 音頻設定
  int get audioCacheSize => int.tryParse(_getWebEnv('AUDIO_CACHE_SIZE') ?? dotenv.env['AUDIO_CACHE_SIZE'] ?? '100') ?? 100;
  int get audioCacheDuration => int.tryParse(_getWebEnv('AUDIO_CACHE_DURATION') ?? dotenv.env['AUDIO_CACHE_DURATION'] ?? '3600') ?? 3600;

  // 遊戲設定
  int get gameMaxLevel => int.tryParse(_getWebEnv('GAME_MAX_LEVEL') ?? dotenv.env['GAME_MAX_LEVEL'] ?? '10') ?? 10;
  int get gameDifficultyInterval => int.tryParse(_getWebEnv('GAME_DIFFICULTY_INTERVAL') ?? dotenv.env['GAME_DIFFICULTY_INTERVAL'] ?? '2') ?? 2;
} 