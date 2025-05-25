import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

// 條件導入以支持Web平台
import 'dart:io' if (dart.library.html) 'native_file_stub.dart';

// 導入Web安全語音服務
import 'web_safe_speech_service.dart';

enum RecordingStatus {
  notStarted,
  recording,
  paused,
  stopped,
}

class ImprovedSpeechService {
  late AudioRecorder _recorder;
  RecordingStatus _status = RecordingStatus.notStarted;
  String? _currentPath;

  // 錄音設置 - 增強配置以提高錄音質量和音量
  final RecordConfig _highQualityConfig = RecordConfig(
    encoder: AudioEncoder.aacLc,
    bitRate: 192000,
    sampleRate: 44100,
    numChannels: 2,
    autoGain: true,      // 開啟自動增益控制，提高錄音音量
    echoCancel: false,   // 關閉回聲消除，保留更多原始聲音
    noiseSuppress: false // 關閉噪音抑制，確保錄音完整性
  );

  final RecordConfig _lowLatencyConfig = RecordConfig(
    encoder: AudioEncoder.aacLc,
    bitRate: 96000,
    sampleRate: 22050,
    numChannels: 1,
  );

  // 聲音水平監聽器
  Stream<double>? _amplitudeStream;
  StreamSubscription<double>? _amplitudeSubscription;
  Function(double)? _onAmplitudeChanged;

  // 單例模式
  static final ImprovedSpeechService _instance =
      ImprovedSpeechService._internal();

  factory ImprovedSpeechService() {
    return _instance;
  }

  ImprovedSpeechService._internal() {
    _recorder = AudioRecorder();
    if (kIsWeb) {
      _webSpeechService = WebSafeSpeechService();
      print('ImprovedSpeechService: 初始化 WebSafeSpeechService');
    }
  }

  RecordingStatus get status => _status;
  String? get recordingPath => _currentPath;

  // 檢查麥克風權限
  Future<bool> checkPermission() async {
    try {
      return await _recorder.hasPermission();
    } catch (e) {
      print('檢查麥克風權限失敗: $e');
      return false;
    }
  }

  // Web平台語音服務
  WebSafeSpeechService? _webSpeechService;

  // 開始錄音
  Future<bool> startRecording({bool lowLatency = false}) async {
    // 在Web平台上使用WebSafeSpeechService
    if (kIsWeb) {
      if (_webSpeechService == null) {
        _webSpeechService = WebSafeSpeechService();
        print('ImprovedSpeechService: 延遲初始化 WebSafeSpeechService');
      }
      print('Web平台: 使用 WebSafeSpeechService 開始錄音');
      final result = await _webSpeechService!.startRecording();
      if (result) {
        _status = RecordingStatus.recording;
        print('WebSafeSpeechService 錄音開始成功');
      } else {
        print('WebSafeSpeechService 錄音開始失敗');
      }
      return result;
    }

    if (_status == RecordingStatus.recording) {
      return true;
    }

    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) {
        return false;
      }

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentPath = '${tempDir.path}/recording_$timestamp.m4a';

      await _recorder.start(
        lowLatency ? _lowLatencyConfig : _highQualityConfig,
        path: _currentPath!,
      );

      _status = RecordingStatus.recording;

      // 開始監聽聲音水平
      _startAmplitudeMonitoring();

      return true;
    } catch (e) {
      print('開始錄音失敗: $e');
      return false;
    }
  }

  // 開始監聽聲音水平
  void _startAmplitudeMonitoring() {
    if (kIsWeb) return; // Web平台上不支持

    _amplitudeStream =
        Stream.periodic(const Duration(milliseconds: 200)).asyncMap((_) async {
      try {
        final amplitude = await _recorder.getAmplitude();
        return amplitude.current ?? 0.0;
      } catch (e) {
        return 0.0;
      }
    });

    _amplitudeSubscription = _amplitudeStream?.listen((amplitude) {
      if (_onAmplitudeChanged != null) {
        _onAmplitudeChanged!(amplitude);
      }
    });
  }

  // 停止監聽聲音水平
  void _stopAmplitudeMonitoring() {
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
  }

  // 設置聲音水平變化回調
  void setOnAmplitudeChanged(Function(double) onAmplitudeChanged) {
    _onAmplitudeChanged = onAmplitudeChanged;
  }

  // 暫停錄音
  Future<bool> pauseRecording() async {
    if (_status != RecordingStatus.recording) {
      return false;
    }

    try {
      await _recorder.pause();
      _status = RecordingStatus.paused;
      return true;
    } catch (e) {
      print('暫停錄音失敗: $e');
      return false;
    }
  }

  // 恢復錄音
  Future<bool> resumeRecording() async {
    if (_status != RecordingStatus.paused) {
      return false;
    }

    try {
      await _recorder.resume();
      _status = RecordingStatus.recording;
      return true;
    } catch (e) {
      print('恢復錄音失敗: $e');
      return false;
    }
  }

  // 停止錄音
  Future<String?> stopRecording() async {
    if (_status != RecordingStatus.recording &&
        _status != RecordingStatus.paused) {
      print('停止錄音: 當前非錄音狀態，無法停止');
      return null;
    }

    // Web平台上使用WebSafeSpeechService
    if (kIsWeb) {
      _webSpeechService ??= WebSafeSpeechService();
      _status = RecordingStatus.stopped;
      print('Web平台: 使用 WebSafeSpeechService 停止錄音');
      String? url = await _webSpeechService!.stopRecording();
      if (url != null) {
        print('WebSafeSpeechService 成功錄音，URL: $url');
      } else {
        print('WebSafeSpeechService 錄音失敗，返回虛擬路徑');
        url = 'web_recording.m4a';
      }
      return url;
    }

    try {
      // 停止監聽聲音水平
      _stopAmplitudeMonitoring();

      print('停止錄音中...');
      final result = await _recorder.stop();
      _status = RecordingStatus.stopped;
      
      // 使用返回的結果正確更新路徑
      if (result != null && result.isNotEmpty) {
        _currentPath = result;
        print('錄音服務返回的路徑: $_currentPath');
      }
      
      // 驗證錄音文件
      if (_currentPath != null) {
        try {
          final file = File(_currentPath!);
          final exists = await file.exists();
          final size = exists ? await file.length() : 0;
          print('錄音文件檢查：路徑=$_currentPath, 存在=$exists, 大小=$size bytes');
          
          if (!exists) {
            print('錯誤：錄音文件不存在');
            return null;
          } else if (size < 100) { 
            print('錯誤：錄音文件太小，可能錄音失敗，大小=$size bytes');
            // 返回檔案路徑，但在控制台高亮警告
            return _currentPath;
          }
        } catch (e) {
          print('檢查錄音文件時出錯: $e');
        }
      } else {
        print('錯誤：沒有獲得錄音路徑');
        return null;
      }
      
      print('停止錄音成功，路徑: $_currentPath');
      return _currentPath;
    } catch (e) {
      print('停止錄音失敗: $e');
      return null;
    }
  }

  // 評分發音 (模擬功能，未來整合真實語音識別API)
  Future<Map<String, dynamic>> evaluatePronunciation(
      String recordingPath, String targetText) async {
    // Web平台上使用WebSafeSpeechService
    if (kIsWeb) {
      _webSpeechService ??= WebSafeSpeechService();
      return await _webSpeechService!
          .evaluatePronunciation(recordingPath, targetText);
    }

    // 模擬評分功能，實際項目中應該整合語音識別API
    await Future.delayed(Duration(seconds: 1));

    // 根據單字難度調整評分
    final wordDifficulty = _getWordDifficulty(targetText);

    // 模擬評分結果
    double accuracy;
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    // 根據單字難度調整分數範圍
    switch (wordDifficulty) {
      case WordDifficulty.easy:
        accuracy = 80 + (random * 0.2); // 80-100分之間
        break;
      case WordDifficulty.medium:
        accuracy = 70 + (random * 0.3); // 70-100分之間
        break;
      case WordDifficulty.hard:
        accuracy = 60 + (random * 0.4); // 60-100分之間
        break;
    }

    // 分數不超過100
    accuracy = accuracy.clamp(0, 100);

    // 根據分數給出具體建議
    String detailedFeedback;
    if (accuracy > 90) {
      detailedFeedback = '發音非常標準，繼續保持！';
    } else if (accuracy > 80) {
      detailedFeedback = '發音很好，注意語調的起伏。';
    } else if (accuracy > 70) {
      detailedFeedback = '發音不錯，可以再清晰一些。';
    } else if (accuracy > 60) {
      detailedFeedback = '基本發音正確，需要多練習。';
    } else {
      detailedFeedback = '需要更多練習，注意聽清原音。';
    }

    return {
      'score': accuracy,
      'feedback': accuracy > 80
          ? '發音很好!'
          : accuracy > 60
              ? '發音不錯，繼續練習!'
              : '請再試一次!',
      'detailedFeedback': detailedFeedback,
      'recognizedText': targetText, // 模擬識別出的文字，實際應從API獲取
      'perfectMatch': accuracy > 90, // 是否完美匹配
    };
  }

  // 根據單字長度和複雜性評估難度
  WordDifficulty _getWordDifficulty(String text) {
    // 去除標點符號，分割成單詞
    final words = text.replaceAll(RegExp(r'[^\w\s]'), '').split(' ');

    // 如果是句子，根據句子長度判斷
    if (words.length > 3) {
      return words.length > 8 ? WordDifficulty.hard : WordDifficulty.medium;
    }

    // 單詞難度判斷
    final word = words.first.toLowerCase();

    // 簡單單詞特徵: 短，常見元音發音
    if (word.length <= 4 && _hasSimpleVowels(word)) {
      return WordDifficulty.easy;
    }

    // 困難單詞特徵: 長，複雜發音組合
    if (word.length >= 8 || _hasComplexSounds(word)) {
      return WordDifficulty.hard;
    }

    // 其他情況為中等難度
    return WordDifficulty.medium;
  }

  // 檢查是否包含簡單元音
  bool _hasSimpleVowels(String word) {
    final simplePatterns = ['a', 'e', 'i', 'o', 'u', 'ay', 'ee', 'oo'];

    return simplePatterns.any((pattern) => word.contains(pattern));
  }

  // 檢查是否包含複雜發音組合
  bool _hasComplexSounds(String word) {
    final complexPatterns = [
      'ough',
      'augh',
      'eigh',
      'ph',
      'th',
      'sch',
      'tch',
      'tion',
      'sion'
    ];

    return complexPatterns.any((pattern) => word.contains(pattern));
  }

  // 釋放資源
  void dispose() {
    _stopAmplitudeMonitoring();
    _recorder.dispose();
  }
}

enum WordDifficulty {
  easy,
  medium,
  hard,
}
