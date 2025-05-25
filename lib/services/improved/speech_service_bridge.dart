import 'package:flutter/foundation.dart';
import 'speech_service.dart'; // 修正原生語音服務的導入路徑
import 'web_safe_speech_service.dart';

/// 語音服務橋接器，根據平台選擇合適的語音服務實現
/// 提供統一的接口，同時處理Web平台上的特殊情況
class SpeechServiceBridge {
  // 內部服務實例
  final dynamic _service;

  // 單例模式
  static final SpeechServiceBridge _instance = SpeechServiceBridge._internal();

  factory SpeechServiceBridge() {
    return _instance;
  }

  SpeechServiceBridge._internal() : _service = _createPlatformService();

  // 根據平台創建合適的服務實例
  static dynamic _createPlatformService() {
    if (kIsWeb) {
      print('使用Web安全語音服務');
      return WebSafeSpeechService();
    } else {
      print('使用標準語音服務');
      return ImprovedSpeechService(); // 修正實例化名稱
    }
  }

  // 獲取錄音狀態
  bool get isRecording {
    try {
      if (kIsWeb) {
        return (_service as WebSafeSpeechService).isRecording;
      } else {
        return (_service as ImprovedSpeechService).status == RecordingStatus.recording; // 修正類型轉換
      }
    } catch (e) {
      print('獲取錄音狀態失敗: $e');
      return false;
    }
  }

  // 獲取錄音路徑
  String? get recordingPath {
    try {
      if (kIsWeb) {
        return (_service as WebSafeSpeechService).recordingUrl;
      } else {
        return (_service as ImprovedSpeechService).recordingPath; // 修正類型轉換
      }
    } catch (e) {
      print('獲取錄音路徑失敗: $e');
      return null;
    }
  }

  // 檢查麥克風權限
  Future<bool> checkPermission() async {
    try {
      return await _service.checkPermission();
    } catch (e) {
      print('檢查麥克風權限失敗(已處理): $e');
      return false;
    }
  }

  // 開始錄音
  Future<bool> startRecording({bool lowLatency = false}) async {
    try {
      if (kIsWeb) {
        return await (_service as WebSafeSpeechService).startRecording();
      } else {
        return await (_service as ImprovedSpeechService).startRecording(); // 修正類型轉換
      }
    } catch (e) {
      print('開始錄音失敗(已處理): $e');
      return false;
    }
  }

  // 暫停錄音
  Future<bool> pauseRecording() async {
    try {
      if (kIsWeb) {
        // Web平台不支持暫停錄音
        return false;
      } else {
        return await (_service as ImprovedSpeechService).pauseRecording(); // 修正類型轉換
      }
    } catch (e) {
      print('暫停錄音失敗(已處理): $e');
      return false;
    }
  }

  // 恢復錄音
  Future<bool> resumeRecording() async {
    try {
      if (kIsWeb) {
        // Web平台不支持恢復錄音
        return false;
      } else {
        return await (_service as ImprovedSpeechService).resumeRecording(); // 修正類型轉換
      }
    } catch (e) {
      print('恢復錄音失敗(已處理): $e');
      return false;
    }
  }

  // 停止錄音
  Future<String?> stopRecording() async {
    try {
      final result = await _service.stopRecording();
      print('停止錄音結果: $result');
      return result;
    } catch (e) {
      print('停止錄音失敗(已處理): $e');
      return null;
    }
  }

  // 評分發音
  Future<Map<String, dynamic>> evaluatePronunciation(
      String recordingPath, String targetText) async {
    try {
      return await _service.evaluatePronunciation(recordingPath, targetText);
    } catch (e) {
      print('評分發音失敗(已處理): $e');
      // 返回一個默認的評分結果
      return {
        'score': 70.0,
        'feedback': '發音不錯，繼續練習!',
        'detailedFeedback': '系統無法評估您的發音，但請繼續練習!',
        'recognizedText': targetText,
        'perfectMatch': false,
      };
    }
  }

  // 設置聲音水平變化回調
  void setOnAmplitudeChanged(Function(double) onAmplitudeChanged) {
    try {
      if (kIsWeb) {
        (_service as WebSafeSpeechService)
            .setOnAmplitudeChanged(onAmplitudeChanged);
      // 修正類型檢查，原生服務類別名稱應為 SpeechService
      // 保持這裡的類型檢查為 ImprovedSpeechService
      } else if (_service is ImprovedSpeechService) {
        (_service as ImprovedSpeechService)
            .setOnAmplitudeChanged(onAmplitudeChanged);
      }
    } catch (e) {
      print('設置聲音水平變化回調失敗(已處理): $e');
    }
  }

  // 獲取聲音水平流
  Stream<double>? getAmplitudeStream() {
    try {
      if (kIsWeb) {
        return (_service as WebSafeSpeechService).getAmplitudeStream();
      } else {
        // 非Web平台可能不支持
        return null;
      }
    } catch (e) {
      print('獲取聲音水平流失敗(已處理): $e');
      return null;
    }
  }

  // 釋放資源
  void dispose() {
    try {
      _service.dispose();
    } catch (e) {
      print('釋放語音資源失敗(已處理): $e');
    }
  }
}
