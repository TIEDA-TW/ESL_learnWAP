import 'package:flutter/foundation.dart';
import 'audio_service.dart' show ImprovedAudioService;
import 'web_safe_audio_service.dart';

/// 音頻服務橋接器，根據平台選擇合適的音頻服務實現
/// 提供統一的接口，同時處理Web平台上的特殊情況
class AudioServiceBridge {
  // 內部服務實例
  final dynamic _service;

  // 單例模式
  static final AudioServiceBridge _instance = AudioServiceBridge._internal();

  factory AudioServiceBridge() {
    return _instance;
  }

  AudioServiceBridge._internal() : _service = _createPlatformService();


  // 根據平台創建合適的服務實例
  static dynamic _createPlatformService() {
    if (kIsWeb) {
      print('使用Web安全音頻服務');
      return WebSafeAudioService();
    } else {
      print('使用標準音頻服務');
      return ImprovedAudioService();
    }
  }

  Future<void> setPlaybackSpeed(double rate) async {
    try {
      print('AudioServiceBridge: _service type: \${_service.runtimeType}');
      if (_service is WebSafeAudioService) {
        (_service as WebSafeAudioService).setPlaybackRate(rate);
        print('Web平台已更新播放速度變數為: \$rate，實際播放時會套用');
      } else {
        await _service.setPlaybackSpeed(rate);
      }
    } catch (e) {
      print('設置播放速度失敗(已處理): \$e');
    }
  }

void setOnCompleteListener(Function? onComplete) {
  try {
    _service.setOnCompleteListener(onComplete);
  } catch (e) {
    print('設置完成回調失敗(已處理): \$e');
  }
}

  // 播放音頻文件
  Future<void> playAudio(String audioPath,
      {double rate = 1.0, bool isChinese = false}) async {
    try {
      // 如果音檔路徑為空，直接返回
      if (audioPath.isEmpty) {
        print('音頻路徑為空，無法播放');
        return;
      }

      await _service.playAudio(audioPath, rate: rate);
    } catch (e) {
      print('播放音頻失敗(已處理): $e');
    }
  }

  // 播放設備上的錄音文件
  Future<void> playRecording(String filePath) async {
    try {
      await _service.playRecording(filePath);
    } catch (e) {
      print('播放錄音失敗(已處理): $e');
    }
  }

  // 播放音效
  Future<void> playEffect(String effectPath) async {
    try {
      if (_service is WebSafeAudioService) {
        await (_service as WebSafeAudioService).playEffect(effectPath);
      }
    } catch (e) {
      print('播放音效失敗(已處理): $e');
    }
  }

  // 播放正確答案音效
  Future<void> playCorrectEffect() async {
    try {
      if (_service is WebSafeAudioService) {
        await (_service as WebSafeAudioService).playCorrectEffect();
      }
    } catch (e) {
      print('播放正確答案音效失敗(已處理): $e');
    }
  }

  // 播放錯誤答案音效
  Future<void> playIncorrectEffect() async {
    try {
      if (_service is WebSafeAudioService) {
        await (_service as WebSafeAudioService).playIncorrectEffect();
      }
    } catch (e) {
      print('播放錯誤答案音效失敗(已處理): $e');
    }
  }

  // 停止播放
  Future<void> stopAudio() async {
    try {
      await _service.stopAudio();
    } catch (e) {
      print('停止音頻失敗(已處理): $e');
    }
  }

  // 暫停播放
  Future<void> pauseAudio() async {
    try {
      await _service.pauseAudio();
    } catch (e) {
      print('暫停音頻失敗(已處理): $e');
    }
  }

  // 恢復播放
  Future<void> resumeAudio() async {
    try {
      await _service.resumeAudio();
    } catch (e) {
      print('恢復播放失敗(已處理): $e');
    }
  }

  // 設置播放速度
  Future<void> setPlaybackRate(double rate) async {
    try {
      if (_service is WebSafeAudioService) {
        await (_service as WebSafeAudioService).setPlaybackRate(rate);
      } else {
        await _service.setPlaybackRate(rate);
      }
    } catch (e) {
      print('設置播放速度失敗(已處理): $e');
    }
  }

  // 重置播放速度
  Future<void> resetPlaybackRate() async {
    try {
      await _service.resetPlaybackRate();
    } catch (e) {
      print('重置播放速度失敗(已處理): $e');
    }
  }


  // 獲取音頻持續時間
  Future<Duration> getAudioDuration(String audioPath) async {
    try {
      if (_service is WebSafeAudioService) {
        return await (_service as WebSafeAudioService)
            .getAudioDuration(audioPath);
      }
      return const Duration(seconds: 2);
    } catch (e) {
      print('獲取音頻持續時間失敗(已處理): $e');
      return const Duration(seconds: 2);
    }
  }

  // 釋放資源
  void dispose() {
    try {
      _service.dispose();
    } catch (e) {
      print('釋放音頻資源失敗(已處理): $e');
    }
  }

  // 代理屬性
  bool get isPlaying {
    try {
      if (_service is WebSafeAudioService) {
        return (_service as WebSafeAudioService).isPlaying;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  double get playbackRate {
    try {
      if (_service is WebSafeAudioService) {
        return (_service as WebSafeAudioService).playbackRate;
      }
      return 1.0;
    } catch (e) {
      return 1.0;
    }
  }
}
