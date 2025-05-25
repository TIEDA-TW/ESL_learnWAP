// 這是 reader_screen.dart 中需要更新的兩個方法:

// 添加這個辅助方法:
// 播放原音後啟用錄音按鈕
Future<void> _playOriginalAudio(Function? onComplete) async {
  try {
    if (_activeRegion == null) return;

    // 確保先停止所有音頻
    await _audioService.stopAudio();

    setState(() {
      _isPlayingOriginalAudio = true;
      _canStartRecording = false; // 除非播放完成，否則不允許錄音
    });

    await _playAudio(_activeRegion!.audioFile);

    // 原音播放完畢
    setState(() {
      _isPlayingOriginalAudio = false;
      _canStartRecording = true; // 許可錄音
    });

    // 顯示一個提示
    if (mounted && _isInResultDialog) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('原音播放完成，現在可以開始錄音'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    }

    if (onComplete != null) {
      onComplete();
    }
  } catch (e) {
    print('播放原音失敗: $e');
    setState(() {
      _isPlayingOriginalAudio = false;
      _canStartRecording = true; // 即使失敗也許可錄音
    });
  }
}

// 修改跟讀對話框方法:
// 顯示跟讀對話框
Future<void> _showSpeakingDialog() async {
  if (_activeRegion == null) return;

  // 設置狀態為對話框打開
  setState(() {
    _isInResultDialog = true;
    _canStartRecording = true; // 初始狀態允許錄音，不再需要先播放原音
  });

  // 顯示跟讀對話框
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: Text('跟讀',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          contentPadding: EdgeInsets.all(20),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${_activeRegion?.text ?? ""}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                    textAlign: TextAlign.center),
                SizedBox(height: 20),
                Text(
                  _isPlayingOriginalAudio
                      ? '正在播放原音...'
                      : _isRecording
                          ? '正在錄音...'
                          : _isPlayingRecordedAudio
                              ? '正在播放錄音...'
                              : _canStartRecording
                                  ? '現在可以開始錄音'
                                  : '請先播放原音',
                  style: TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                // 移除"請先點擊「播放原音」按鈕"的提示
              ],
            ),
          ),
          actionsPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          actions: [
            // 播放原音按鈕
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isPlayingOriginalAudio ||
                        _isRecording ||
                        _isPlayingRecordedAudio
                    ? null
                    : () {
                        _audioService.stopAudio();
                        setDialogState(() {
                          _isPlayingOriginalAudio = true;
                          _isPlayingRecordedAudio = false;
                          // 不再设置_canStartRecording为false
                        });
                        setState(() {
                          _isPlayingOriginalAudio = true;
                          _isPlayingRecordedAudio = false;
                          // 不再设置_canStartRecording为false
                        });

                        _playAudio(_activeRegion!.audioFile).then((_) {
                          if (mounted) {
                            setDialogState(() {
                              _isPlayingOriginalAudio = false;
                              _canStartRecording = true; // 原音播放完畢，現在可以錄音
                            });
                            setState(() {
                              _isPlayingOriginalAudio = false;
                              _canStartRecording = true; // 原音播放完畢，現在可以錄音
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('原音播放完成'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        });
                      },
                icon: Icon(Icons.volume_up, size: 28),
                label: Text('播放原音', style: TextStyle(fontSize: 20)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            SizedBox(height: 10),
            // 錄音按鈕 - 必須先播放原音才能啟用此按鈕
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: (_isPlayingOriginalAudio || _isPlayingRecordedAudio)
                    ? null
                    : () {
                        if (_isRecording) {
                          // 如果正在錄音，則停止錄音
                          _stopRecording().then((_) {
                            // 更新對話框狀態
                            setDialogState(() {
                              // 明確在對話框狀態中更新錄音狀態
                              _isRecording = false;
                            });
                          });
                        } else {
                          // 開始錄音
                          _beginRecording().then((_) {
                            // 確保在對話框狀態中也更新錄音狀態
                            setDialogState(() {
                              // 明確在對話框狀態中更新錄音狀態
                              _isRecording = true;
                            });
                          });
                        }
                      },
                icon: Icon(_isRecording ? Icons.stop : Icons.mic, size: 28),
                label: Text(
                  _isRecording ? '停止錄音' : '開始錄音',
                  style: TextStyle(fontSize: 20),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRecording ? Colors.red : Colors.green,
                  padding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            SizedBox(height: 10),
            // 播放錄音按鈕
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: (_lastRecordingPath != null &&
                        !_isPlayingOriginalAudio &&
                        !_isRecording &&
                        !_isPlayingRecordedAudio)
                    ? () {
                        _audioService.stopAudio();
                        setDialogState(() {
                          _isPlayingRecordedAudio = true;
                        });
                        setState(() {
                          _isPlayingRecordedAudio = true;
                        });
                        try {
                          _playRecordedAudio().then((_) {
                            if (mounted) {
                              setDialogState(() {
                                _isPlayingRecordedAudio = false;
                              });
                              setState(() {
                                _isPlayingRecordedAudio = false;
                              });
                              // 若播放成功，顯示成功訊息
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('播放錄音成功！'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          });
                        } catch (e) {
                          print('播放錄音失敗: $e');
                          // 顯示錯誤訊息
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('播放錄音失敗，請重新錄音'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          setDialogState(() {
                            _isPlayingRecordedAudio = false;
                          });
                          setState(() {
                            _isPlayingRecordedAudio = false;
                          });
                        }
                      }
                    : null,
                icon: Icon(Icons.headphones, size: 28),
                label: Text('播放錄音', style: TextStyle(fontSize: 20)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            SizedBox(height: 10),
            // 關閉按鈕
            SizedBox(
              width: double.infinity,
              height: 50,
              child: TextButton(
                onPressed: () {
                  _audioService.stopAudio();
                  if (_isRecording) {
                    _speechService.stopRecording();
                  }
                  setState(() {
                    _isPlayingOriginalAudio = false;
                    _isPlayingRecordedAudio = false;
                    _isRecording = false;
                    _isInResultDialog = false;
                  });
                  Navigator.of(context).pop();
                },
                child: Text('關閉', style: TextStyle(fontSize: 20)),
                style: ButtonStyle(
                  padding: MaterialStateProperty.all(
                      EdgeInsets.symmetric(vertical: 10)),
                ),
              ),
            ),
          ],
        );
      },
    ),
  ).then((_) {
    // 對話框關閉時停止音頻和錄音
    _audioService.stopAudio();
    if (_isRecording) {
      _speechService.stopRecording();
    }
    setState(() {
      _isPlayingOriginalAudio = false;
      _isPlayingRecordedAudio = false;
      _isRecording = false;
      _isInResultDialog = false;
    });
  });
}
