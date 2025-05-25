import 'dart:async';

class SpeechService {
  Future<bool> checkPermission() async {
    // 模擬總是有權限
    return true;
  }

  Future<bool> startRecording() async {
    // 模擬開始錄音成功
    return true;
  }

  Future<String?> stopRecording() async {
    // 模擬錄音檔案路徑
    return 'mock_recording.wav';
  }

  Future<Map<String, dynamic>> evaluatePronunciation(String path, String text) async {
    // 模擬評估結果
    await Future.delayed(Duration(milliseconds: 500));
    return {
      'score': 85,
      'feedback': '發音不錯，繼續加油！',
    };
  }

  void dispose() {
    // 釋放資源
  }
}