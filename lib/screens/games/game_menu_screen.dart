
import 'package:flutter/material.dart';
import '../../models/book_model.dart';
import '../../services/game_service.dart';
import 'word_match_screen.dart';
import 'sentence_fill_screen.dart';
import 'picture_diff_screen.dart';

class GameMenuScreen extends StatelessWidget {
  final Book book;
  final GameService gameService;

  GameMenuScreen({required this.book, required this.gameService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('遊戲選單')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: Text('單詞配對'),
              onPressed: () async {
                // 根據書籍生成單詞配對遊戲數據
                final gameData = await gameService.generateWordMatchData(book);
                // 進入單詞配對遊戲頁面
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WordMatchScreen(gameData: gameData)),
                );
              },
            ),
            ElevatedButton(
              child: Text('句子填空'),
              onPressed: () async {
                // 根據書籍生成句子填空遊戲數據 
                final gameData = await gameService.generateSentenceFillData(book);
                // 進入句子填空遊戲頁面
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SentenceFillScreen(gameData: gameData)),
                );
              },
            ),
            ElevatedButton(
              child: Text('圖片找茬'),
              onPressed: () async {
                // 根據書籍生成圖片找茬遊戲數據
                final gameData = await gameService.generatePictureDiffData(book);
                // 進入圖片找茬遊戲頁面  
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PictureDiffScreen(gameData: gameData)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
