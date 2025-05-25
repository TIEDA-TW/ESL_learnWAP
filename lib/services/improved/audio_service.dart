import 'dart:io';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class ImprovedAudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _effectPlayer = AudioPlayer(); // 用於播放音效
  
  bool _isPlaying = false;
  double _playbackRate = 1.0;
  
  // 單例模式
  static final ImprovedAudioService _instance = ImprovedAudioService._internal();
  
  factory ImprovedAudioService() {
    return _instance;
  }
  
  ImprovedAudioService._internal();

  Future<void> setPlaybackSpeed(double rate) async {
    try {
      await _audioPlayer.setPlaybackRate(rate);
      _playbackRate = rate;
    } catch (e) {
      print('設置播放速度失敗: \$e');
    }
  }
  
  bool get isPlaying => _isPlaying;
  double get playbackRate => _playbackRate;
  
  // 播放音頻文件
  Future<void> playAudio(String audioPath, {double rate = 1.0}) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(
        AssetSource(audioPath),
        mode: PlayerMode.lowLatency,
      );
      await _audioPlayer.setPlaybackRate(rate);
      _isPlaying = true;
      _playbackRate = rate;
    } catch (e) {
      print('播放音頻失敗: $e');
      rethrow;
    }
  }
  
  // 播放設備上的錄音文件
  Future<void> playRecording(String filePath) async {
    try {
      await _audioPlayer.stop();
      
      // 判斷是否為Web虛擬錄音
      if (filePath == 'web_recording.m4a') {
        // Web平台上不做任何播放，因為我們沒有實際錄音
        // 只是等待一下讓用戶感覺有播放
        await Future.delayed(Duration(milliseconds: 500));
      } else {
        await _audioPlayer.play(
          DeviceFileSource(filePath),
          mode: PlayerMode.mediaPlayer,
        );
      }
      _isPlaying = true;
    } catch (e) {
      print('播放錄音失敗: $e');
      rethrow;
    }
  }
  
  // 播放音效
  Future<void> playEffect(String effectPath) async {
    try {
      await _effectPlayer.stop();
      await _effectPlayer.play(
        AssetSource(effectPath),
        mode: PlayerMode.lowLatency,
      );
    } catch (e) {
      print('播放音效失敗: $e');
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
      await _audioPlayer.stop();
      _isPlaying = false;
    } catch (e) {
      print('停止音頻失敗: $e');
    }
  }
  
  // 暫停播放
  Future<void> pauseAudio() async {
    await _audioPlayer.pause();
    _isPlaying = false;
  }
  
  // 恢復播放
  Future<void> resumeAudio() async {
    await _audioPlayer.resume();
    _isPlaying = true;
  }
  
  // 設置播放速度
  Future<void> setPlaybackRate(double rate) async {
    await _audioPlayer.setPlaybackRate(rate);
    _playbackRate = rate;
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
  
  // 設置播放完成回調
  void setOnCompleteListener(Function() onComplete) {
    _audioPlayer.onPlayerComplete.listen((_) {
      _isPlaying = false;
      onComplete();
    });
  }
  
  // 獲取音頻持續時間
  Future<Duration?> getAudioDuration(String audioPath) async {
    try {
      // 從路徑加載音頻
      final player = AudioPlayer();
      await player.setSource(AssetSource(audioPath));
      
      // 等待加載完成
      await Future.delayed(const Duration(milliseconds: 200));
      
      // 獲取持續時間
      final duration = player.getDuration();
      
      // 釋放資源
      await player.dispose();
      
      return duration;
    } catch (e) {
      print('獲取音頻持續時間失敗: $e');
      return null;
    }
  }
  
  // 釋放資源
  void dispose() {
    _audioPlayer.dispose();
    _effectPlayer.dispose();
  }
}