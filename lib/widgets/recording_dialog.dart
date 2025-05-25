import 'package:flutter/material.dart';
import '../services/improved/audio_service_bridge.dart'; // 導入 AudioServiceBridge
import '../services/improved/speech_service_bridge.dart'; // 導入 SpeechServiceBridge

class RecordingDialog extends StatefulWidget {
  final AudioServiceBridge audioService; // 保留 AudioServiceBridge 用於播放
  final SpeechServiceBridge speechService; // 添加 SpeechServiceBridge 用於錄音狀態和控制

  const RecordingDialog({
    Key? key,
    required this.audioService,
    required this.speechService, // 添加 speechService 到構造函數
  }) : super(key: key);

  @override
  State<RecordingDialog> createState() => _RecordingDialogState();
}

class _RecordingDialogState extends State<RecordingDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.speechService.isRecording ? '正在錄音...' : '錄音完成'), // 使用 speechService 判斷錄音狀態
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.speechService.isRecording) // 使用 speechService 判斷錄音狀態
            const CircularProgressIndicator()
          else if (widget.speechService.recordingPath != null) // 使用 speechService 獲取錄音路徑
            const Text('要播放錄音嗎？'),
        ],
      ),
      actions: [
        if (widget.speechService.isRecording) // 使用 speechService 判斷錄音狀態
          TextButton(
            onPressed: () async {
              await widget.speechService.stopRecording(); // 使用 speechService 停止錄音
              setState(() {});
            },
            child: const Text('停止錄音'),
          )
        else ...[
          if (widget.speechService.recordingPath != null) ...[ // 使用 speechService 獲取錄音路徑
            TextButton(
              // 播放錄音仍然使用 audioService，但需要傳遞正確的路徑
              onPressed: () => widget.audioService.playRecording(widget.speechService.recordingPath!),
              child: const Text('播放錄音'),
            ),
            TextButton(
              onPressed: () async {
                await widget.speechService.startRecording(); // 使用 speechService 開始錄音
                setState(() {});
              },
              child: const Text('重新錄音'),
            ),
          ],
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('關閉'),
          ),
        ],
      ],
    );
  }
}