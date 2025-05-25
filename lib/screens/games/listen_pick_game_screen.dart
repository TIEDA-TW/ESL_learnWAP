// listen_pick_game_screen.dart
// 原 listen_pick_game.dart 內容移至此檔案

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import '../../models/vocabulary_model.dart';
import '../../services/improved/tts_service.dart';

class ListenPickGameScreen extends StatefulWidget {
  final String bookId;
  ListenPickGameScreen({Key? key, required this.bookId}) : super(key: key);

  @override
  State<ListenPickGameScreen> createState() => _ListenPickGameScreenState();
}

class _ListenPickGameScreenState extends State<ListenPickGameScreen> with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('聽力選擇遊戲')),
      body: Center(child: Text('這是新版聽力選擇遊戲畫面')),
    );
  }
}
