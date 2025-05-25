// 將這個方法複製替換到 reader_screen.dart 中的 _stopRecording 方法

// 停止錄音 - 增強版本
Future<void> _stopRecording() async {
  if (!_isRecording || _activeRegion == null) {
    print('停止錄音失敗: 未在錄音中或沒有活動區域');
    return;
  }

  print('停止錄音中...');
  final recordingPath = await _speechService.stopRecording();
  print('錄音路徑: $recordingPath');
  
  // 確保錄音文件已完全寫入
  await Future.delayed(const Duration(milliseconds: 800));

  setState(() {
    _isRecording = false;
    _lastRecordingPath = recordingPath;
    _showRecordButton = false;
  });

  // 確保錄音路徑有效
  if (recordingPath != null && recordingPath.isNotEmpty) {
    print('錄音成功，準備播放，路徑: $recordingPath');
    
    // 檢查文件存在性 (僅在非Web平台檢查)
    if (!kIsWeb && recordingPath != 'web_recording.m4a') {
      try {
        final file = File(recordingPath);
        final exists = await file.exists();
        final size = exists ? await file.length() : 0;
        print('錄音文件狀態: 存在=$exists, 大小=$size bytes');
        
        if (!exists || size < 100) {
          print('警告: 錄音文件不存在或太小，可能錄音失敗');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('錄音可能失敗，請再試一次'),
                backgroundColor: Colors.amber,
              ),
            );
          }
          return;
        }
      } catch (e) {
        print('檢查錄音文件時出錯: $e');
      }
    } else if (kIsWeb && recordingPath == 'web_recording.m4a') {
      // Web平台上使用IndexedDB，無需檢查文件，因為已經存儲在IndexedDB中
      print('Web平台錄音 (IndexedDB): $recordingPath');
    }
    
  } else {
    print('錄音失敗或路徑為空');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('錄音失敗，請再試一次'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return;
  }

  if (recordingPath != null) {
    print('準備播放原始音頁和錄音...');
    // 確保音頁已經停止
    await _audioService.stopAudio();

    // 先播放原音
    setState(() {
      _isPlayingOriginalAudio = true;
    });

    try {
      // 播放原始音頁
      print('播放原始音頁: ${_activeRegion!.audioFile}');
      await _playAudio(_activeRegion!.audioFile);

      // 原音播放完成，更新狀態
      if (mounted) {
        setState(() {
          _isPlayingOriginalAudio = false;
        });
      }

      // 等待一下讓用戶能聽清原音
      await Future.delayed(const Duration(milliseconds: 800));

      // 播放錄音
      if (_lastRecordingPath != null && mounted) {
        print('播放錄音: $_lastRecordingPath');
        try {
          setState(() {
            _isPlayingRecordedAudio = true;
          });
          
          // 嘗試先使用特定方法確保音量最大
          await _audioService.stopAudio();
          
          // 播放錄音前先清空任何現有播放
          await Future.delayed(const Duration(milliseconds: 300));
          
          // 再次嘗試播放錄音
          // 在Web環境中、使用虛擬錄音路徑時，實際上會從 IndexedDB 讀取錄音
          await _audioService.playRecording(_lastRecordingPath!);
          print('錄音播放已啟動');
          
          // 設置計時器，確保即使錄音播放失敗也能繼續
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted && _isPlayingRecordedAudio) {
              setState(() {
                _isPlayingRecordedAudio = false;
              });
              print('錄音播放計時器觸發，重設狀態');
            }
          });
        } catch (e) {
          print('播放錄音失敗: $e');
          
          // 嘗試備用方法播放
          try {
            print('嘗試備用方法播放錄音');
            if (!kIsWeb && recordingPath != 'web_recording.m4a') {
              final file = File(recordingPath);
              if (await file.exists()) {
                print('嘗試直接啟動系統音樂播放器來播放錄音');
                
                // 等待一下再嘗試播放
                await Future.delayed(const Duration(milliseconds: 500));
                await _audioService.playRecording(_lastRecordingPath!);
                print('備用方式播放已啟動');
              } else {
                print('錄音文件不存在，無法使用備用方法');
              }
            }
          } catch (backupError) {
            print('備用方法錄音播放也失敗: $backupError');
            
            // 更正狀態並顯示錯誤
            if (mounted) {
              setState(() {
                _isPlayingRecordedAudio = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('播放錄音過程中發生錯誤，請再試一次'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      print('播放原始音頁失敗: $e');
      if (mounted) {
        setState(() {
          _isPlayingOriginalAudio = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('播放原始音頁失敗: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  } else {
    print('錄音失敗');
  }
}
