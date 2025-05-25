import 'package:flutter/material.dart';

class GameResult extends StatelessWidget {
  final int correctCount;
  final int totalCount;
  final double elapsedTime;
  final VoidCallback? onPlayAgain;
  final VoidCallback? onReturnToMenu;

  GameResult({
    required this.correctCount,
    required this.totalCount,
    required this.elapsedTime,
    this.onPlayAgain,
    this.onReturnToMenu,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('遊戲結果'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('正確數: $correctCount / $totalCount'),
          Text('用時: ${elapsedTime.toStringAsFixed(1)} 秒'),
          Text('正確率: ${(correctCount / totalCount * 100).toStringAsFixed(1)}%'),
        ],
      ),
      actions: [
        TextButton(
          child: Text('再玩一次'),
          onPressed: onPlayAgain ?? () => Navigator.pop(context, true),
        ),
        TextButton(
          child: Text('返回選單'),
          onPressed: onReturnToMenu ?? () => Navigator.pop(context, false),
        ),
      ],
    );
  }
}
