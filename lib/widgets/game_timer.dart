import 'dart:async';
import 'package:flutter/material.dart';

class GameTimer extends StatefulWidget {
  final Function(double) onTick;
  final bool isGameOver;

  GameTimer({required this.onTick, this.isGameOver = false});

  @override
  _GameTimerState createState() => _GameTimerState();
}

class _GameTimerState extends State<GameTimer> {
  late Stopwatch _stopwatch;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _timer = Timer.periodic(Duration(milliseconds: 100), (_) {
      if (!widget.isGameOver) {
        widget.onTick(_stopwatch.elapsedMilliseconds / 1000.0);
      }
    });
  }

  @override
  void didUpdateWidget(GameTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isGameOver && !oldWidget.isGameOver) {
      _stopwatch.stop();
    } else if (!widget.isGameOver && oldWidget.isGameOver) {
      _stopwatch.start();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: Stream.periodic(Duration(milliseconds: 100), (_) => _stopwatch.elapsedMilliseconds),
      builder: (context, snapshot) {
        final time = snapshot.data ?? 0;
        return Text(
          '${(time / 1000).toStringAsFixed(1)} s',
          style: TextStyle(fontSize: 24),
        );
      },
    );
  }
}
