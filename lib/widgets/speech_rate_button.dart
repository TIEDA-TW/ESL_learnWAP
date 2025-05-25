import 'package:flutter/material.dart';

/// 可重用的語速切換按鈕元件
/// [speechRates]：語速數值列表，例如 [0.5, 0.7, 1.0]
/// [speechRateLabels]：語速標籤，例如 ['慢', '正常', '快']
/// [currentIndex]：目前語速索引
/// [onRateChanged]：切換語速時的 callback
class SpeechRateButton extends StatelessWidget {
  final List<double> speechRates;
  final List<String> speechRateLabels;
  final int currentIndex;
  final ValueChanged<int> onRateChanged;

  const SpeechRateButton({
    Key? key,
    required this.speechRates,
    required this.speechRateLabels,
    required this.currentIndex,
    required this.onRateChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.speed),
      tooltip: '語速：${speechRateLabels[currentIndex]}',
      onPressed: () {
        int nextIndex = (currentIndex + 1) % speechRates.length;
        onRateChanged(nextIndex);
      },
    );
  }
}
