import 'dart:io';
import 'package:flutter/foundation.dart';

/// 音頻調試工具類，用於輔助調試跟讀功能中的音頻和錄音問題
class AudioDebugHelper {
  /// 檢查錄音文件是否有效
  static Future<bool> isValidRecordingFile(String? filePath) async {
    if (filePath == null || filePath.isEmpty) {
      print('錄音文件路徑為空或無效');
      return false;
    }
    
    // Web平台上自動返回成功
    if (kIsWeb || filePath == 'web_recording.m4a') {
      print('Web平台上無法驗證錄音文件，假設有效');
      return true;
    }
    
    try {
      final file = File(filePath);
      final exists = await file.exists();
      final size = exists ? await file.length() : 0;
      print('錄音文件狀態檢查: 路徑=$filePath, 存在=$exists, 大小=$size bytes');
      
      if (!exists) {
        print('錯誤: 錄音文件不存在');
        return false;
      }
      
      if (size < 100) {
        print('警告: 錄音文件太小 ($size bytes)，可能錄音失敗');
        return false;
      }
      
      return true;
    } catch (e) {
      print('驗證錄音文件時出錯: $e');
      return false;
    }
  }
  
  /// 檢查錄音目錄是否可寫入
  static Future<bool> isRecordingDirWritable() async {
    if (kIsWeb) {
      return true; // Web平台上不需要檢查
    }
    
    try {
      final tempDir = await Directory.systemTemp.createTemp('audio_test');
      final testFile = File('${tempDir.path}/test_write.tmp');
      
      // 嘗試寫入測試文件
      await testFile.writeAsString('Test write access');
      
      // 確認可以讀取回來
      final content = await testFile.readAsString();
      final success = content == 'Test write access';
      
      // 清理測試文件
      await testFile.delete();
      await tempDir.delete();
      
      return success;
    } catch (e) {
      print('檢查錄音目錄寫入權限時出錯: $e');
      return false;
    }
  }
  
  /// 嘗試重新定位錄音文件路徑 (用於錄音文件無法直接訪問時)
  static Future<String?> tryAlternativePlayback(String originalPath) async {
    if (kIsWeb || originalPath == 'web_recording.m4a') {
      return originalPath; // Web平台上不需要重定位
    }
    
    try {
      final file = File(originalPath);
      if (!await file.exists()) {
        print('錄音文件不存在，無法重定位');
        return null;
      }
      
      // 複製到另一個臨時目錄
      final tempDir = await Directory.systemTemp.createTemp('audio_playback');
      final fileName = originalPath.split('/').last;
      final newPath = '${tempDir.path}/$fileName';
      
      // 複製文件
      await file.copy(newPath);
      print('已將錄音文件複製到新位置: $newPath');
      
      return newPath;
    } catch (e) {
      print('嘗試重定位錄音文件時出錯: $e');
      return null;
    }
  }
  
  /// 詳細記錄錄音和播放過程，用於調試
  static void logAudioProcess(String step, {String? path, dynamic details}) {
    final timestamp = DateTime.now().toString();
    final detailStr = details != null ? ': $details' : '';
    print('[$timestamp] 音頻處理 - $step ${path != null ? "(路徑: $path)" : ""} $detailStr');
  }
  
  /// 檢查系統音頻設置
  static Future<Map<String, dynamic>> checkSystemAudioSettings() async {
    final result = <String, dynamic>{
      'timestamp': DateTime.now().toString(),
      'platform': kIsWeb ? 'Web' : Platform.operatingSystem,
    };
    
    if (!kIsWeb) {
      try {
        // 檢查臨時目錄空間
        final tempDir = await Directory.systemTemp.createTemp('audio_check');
        final stat = await tempDir.stat();
        result['tempDirPath'] = tempDir.path;
        result['tempDirExists'] = await tempDir.exists();
        
        // 清理
        await tempDir.delete();
      } catch (e) {
        result['tempDirError'] = e.toString();
      }
    }
    
    return result;
  }
}
