import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sound/flutter_sound.dart';

// 條件導入以支持Web平台
import 'dart:io' if (dart.library.html) 'native_file_stub.dart';
// 導入html，僅用於Web平台
import 'dart:html' as html;
import 'package:web/web.dart' as web;
// 引入 Web 語音服務，用於從 IndexedDB 讀取錄音
import 'web_safe_speech_service.dart';

// 為 PlayerState 創建別名
import 'package:audioplayers_platform_interface/src/api/player_state.dart' as audio;
import 'package:flutter_sound/public/flutter_sound_player.dart' as sound;

/// Web安全的音頻服務，處理Web平台的特殊情況
class WebSafeAudioService {
  // 使用多個音頻播放器以避免資源競爭
  AudioPlayer? _mainPlayer;
  AudioPlayer? _effectPlayer;
  FlutterSoundPlayer? _recordingPlayer;

  bool _isPlaying = false;
  double _playbackRate = 1.0;

  // Web 語音服務，用於操作 IndexedDB 中的錄音
  late WebSafeSpeechService _webSpeechService;
  
  // 單例模式
  static final WebSafeAudioService _instance = WebSafeAudioService._internal();

  factory WebSafeAudioService() {
    return _instance;
  }

  WebSafeAudioService._internal() {
    _initializeAudio();
    _webSpeechService = WebSafeSpeechService();
  }

  Future<void> setPlaybackRate(double rate) async {
    _playbackRate = rate;
    if (_mainPlayer != null) {
      await _mainPlayer!.setPlaybackRate(rate);
      print('AudioPlayer 播放速度已設為: $rate');
    }
    print('Web平台已更新播放速度變數為: $rate，實際播放時會套用');
  }

  Future<void> _initializeAudio() async {
    try {
      // 確保先釋放現有資源
      await _mainPlayer?.dispose();
      await _effectPlayer?.dispose();
      await _recordingPlayer?.closePlayer();

      // 重新初始化播放器
      _mainPlayer = AudioPlayer();
      _effectPlayer = AudioPlayer();
      _recordingPlayer = FlutterSoundPlayer();

      // 初始化音頻播放器
      await _recordingPlayer?.openPlayer();
      
      // 設置播放完成監聽
      _mainPlayer?.onPlayerComplete.listen((_) {
        _isPlaying = false;
        if (_onComplete != null) {
          _onComplete!();
        }
      });

      // 使用 onPlayerStateChanged 來監聽錯誤狀態
      _mainPlayer?.onPlayerStateChanged.listen((state) {
        if (state == audio.PlayerState.completed) {
          _isPlaying = false;
          if (_onComplete != null) {
            _onComplete!();
          }
        } else if (state == audio.PlayerState.stopped) {
          _isPlaying = false;
        }
      });

      print('音頻播放器初始化成功');
    } catch (e) {
      print('音頻播放器初始化失敗: $e');
      // 嘗試重新初始化
      await Future.delayed(const Duration(milliseconds: 500));
      await _initializeAudio();
    }
  }

  // 完成播放回調
  Function? _onComplete;

  void setOnCompleteListener(Function? onComplete) {
    _onComplete = onComplete;
  }

  bool get isPlaying => _isPlaying;
  double get playbackRate => _playbackRate;

  // 安全播放音頻
  Future<void> playAudio(String audioPath, {double? rate}) async {
    print('嘗試播放音頻: $audioPath');
    
    // 確保播放器已初始化
    if (_mainPlayer == null) {
      await _initializeAudio();
    }
    
    try {
      // 確保先停止任何正在播放的音頻
      await _mainPlayer?.stop();
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 播放新音頻
      await _mainPlayer?.play(
        AssetSource(audioPath),
        mode: PlayerMode.lowLatency,
      );
      
      // 設置播放速度
      if (rate != null) {
        await _mainPlayer?.setPlaybackRate(rate);
      }
      
      _isPlaying = true;
      _playbackRate = rate ?? _playbackRate;
      print('音頻播放開始，速度: ${rate ?? _playbackRate}');
    } catch (e) {
      print('播放音頻失敗(已處理): $e');
      if (kIsWeb) {
        // Web環境下的特殊處理
        _isPlaying = true;
        Future.delayed(const Duration(seconds: 2), () {
          _isPlaying = false;
          if (_onComplete != null) {
            _onComplete!();
          }
        });
      } else {
        // 非Web環境下的重試
        await Future.delayed(const Duration(milliseconds: 500));
        await playAudio(audioPath, rate: rate);
      }
    }
  }

  // 播放設備上的錄音文件
  Future<void> playRecording(String filePath) async {
    print('嘗試播放錄音: $filePath');

    // 在Web平台上處理錄音URL
    if (kIsWeb) {
      // 如果是 web_recording.m4a 的虛擬路徑，嘗試從 IndexedDB 讀取
      if (filePath == 'web_recording.m4a') {
        print('偵測到虛擬路徑，從 IndexedDB 讀取錄音...');
        final recordingUrl = await _webSpeechService.getRecordingFromIndexedDB();
        
        if (recordingUrl != null) {
          print('從 IndexedDB 讀取錄音成功，使用URL: $recordingUrl');
          filePath = recordingUrl;
        } else {
          print('IndexedDB 中無錄音，回退到模擬播放');
          _isPlaying = true;
          Future.delayed(const Duration(seconds: 2), () {
            _isPlaying = false;
            if (_onComplete != null) {
              _onComplete!();
            }
            print('模擬播放完成');
          });
          return;
        }
      }
      
      print('Web平台播放錄音URL: $filePath');
      
      // 檢查是否為WebM格式
      final isWebM = filePath.endsWith('.webm') || filePath.startsWith('blob:');
      print('錄音格式: ${isWebM ? 'WebM' : '其他'}');

      try {
        // 使用Web Audio API播放
        final audio = html.AudioElement(filePath);
        
        audio.onEnded.listen((_) {
          _isPlaying = false;
          if (_onComplete != null) {
            _onComplete!();
          }
          print('錄音播放完成');
        });
        
        audio.onError.listen((event) {
          print('播放錄音失敗: ${event.toString()}');
          _isPlaying = false;
          if (_onComplete != null) {
            _onComplete!();
          }
        });

        // 添加canPlayThrough檢查
        final canPlay = await audio.canPlayType('audio/webm') != '';
        if (!canPlay && isWebM) {
          print('瀏覽器不支持WebM格式');
          throw Exception('瀏覽器不支持WebM格式');
        }

        await audio.play();
        _isPlaying = true;
        return;
      } catch (e) {
        print('Web Audio API播放失敗: $e');
        // 回退到模擬播放
        _isPlaying = true;
        Future.delayed(const Duration(seconds: 2), () {
          _isPlaying = false;
          if (_onComplete != null) {
            _onComplete!();
          }
          print('模擬播放完成');
        });
        return;
      }
    }

    // 非Web平台，使用flutter_sound播放
    if (_recordingPlayer == null) {
      _recordingPlayer = FlutterSoundPlayer();
      await _recordingPlayer?.openPlayer();
    }

    try {
      // 停止任何正在播放的錄音
      await _recordingPlayer?.stopPlayer();
      await Future.delayed(const Duration(milliseconds: 100));

      // 非Web平台，播放本地文件
      print('播放本地錄音文件: $filePath');

      // 檢查文件是否存在並具有有效内容 (僅在非Web平台)
      if (!kIsWeb && filePath != 'web_recording.m4a') {
        try {
          final file = File(filePath);
          final exists = await file.exists();
          if (!exists) {
            print('錄音文件不存在: $filePath');
            throw Exception('錄音文件不存在');
          }
          
          final size = await file.length();
          if (size <= 100) {
            print('錄音文件大小太小: $size bytes');
            throw Exception('錄音文件大小太小');
          }
        } catch (fileError) {
          print('錄音文件檢查失敗: $fileError');
          throw Exception('錄音文件無效');
        }
      }

      // 使用flutter_sound播放本地錄音
      await _recordingPlayer?.startPlayer(
        fromURI: filePath,
        codec: Codec.aacMP4,
        whenFinished: () {
          _isPlaying = false;
          if (_onComplete != null) {
            _onComplete!();
          }
          print('錄音播放完成');
        },
      );
      _isPlaying = true;
    } catch (e) {
      print('播放錄音失敗: $e');
      _isPlaying = false;
      if (_onComplete != null) {
        _onComplete!();
      }
      throw Exception('無法播放錄音，請重新錄音');
    }
  }

  // 播放音效
  Future<void> playEffect(String effectPath) async {
    // 確保播放器已初始化
    if (_effectPlayer == null) {
      _effectPlayer = AudioPlayer();
    }

    try {
      await _effectPlayer?.stop();
      await Future.delayed(const Duration(milliseconds: 100));

      await _effectPlayer?.play(
        AssetSource(effectPath),
        mode: PlayerMode.lowLatency,
      );
    } catch (e) {
      print('播放音效失敗(已處理): $e');
    }
  }

  // 播放正確答案音效
  Future<void> playCorrectEffect() async {
    await playEffect('audio/effects/correct.mp3');
  }

  // 播放錯誤答案音效
  Future<void> playIncorrectEffect() async {
    await playEffect('audio/effects/incorrect.mp3');
  }

  // 停止播放
  Future<void> stopAudio() async {
    try {
      await _mainPlayer?.stop();
      _isPlaying = false;
    } catch (e) {
      print('停止音頻失敗(已處理): $e');
      _isPlaying = false;
    }
  }

  // 暫停播放
  Future<void> pauseAudio() async {
    try {
      await _mainPlayer?.pause();
      _isPlaying = false;
    } catch (e) {
      print('暫停音頻失敗(已處理): $e');
      _isPlaying = false;
    }
  }

  // 恢復播放
  Future<void> resumeAudio() async {
    try {
      await _mainPlayer?.resume();
      _isPlaying = true;
    } catch (e) {
      print('恢復播放失敗(已處理): $e');
    }
  }

  // 增加播放速度
  Future<void> increasePlaybackRate() async {
    final newRate = (_playbackRate + 0.1).clamp(0.5, 2.0);
    await setPlaybackRate(newRate);
  }

  // 減少播放速度
  Future<void> decreasePlaybackRate() async {
    final newRate = (_playbackRate - 0.1).clamp(0.5, 2.0);
    await setPlaybackRate(newRate);
  }

  // 重置播放速度
  Future<void> resetPlaybackRate() async {
    await setPlaybackRate(1.0);
  }

  // 獲取音頻持續時間
  Future<Duration> getAudioDuration(String audioPath) async {
    try {
      // 從路徑加載音頻
      final player = AudioPlayer();
      await player.setSource(AssetSource(audioPath));

      // 等待加載完成
      await Future.delayed(const Duration(milliseconds: 300));

      // 獲取持續時間
      final duration = await player.getDuration();

      // 釋放資源
      await player.dispose();

      return duration ?? const Duration(seconds: 2);
    } catch (e) {
      print('獲取音頻持續時間失敗(已處理): $e');
      return const Duration(seconds: 2);
    }
  }

  // 釋放資源
  void dispose() {
    try {
      _mainPlayer?.dispose();
      _effectPlayer?.dispose();
      _recordingPlayer?.closePlayer();
      _mainPlayer = null;
      _effectPlayer = null;
      _recordingPlayer = null;
    } catch (e) {
      print('釋放音頻資源失敗(已處理): $e');
    }
  }
}
