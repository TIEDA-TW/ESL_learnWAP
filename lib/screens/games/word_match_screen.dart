
import 'package:flutter/material.dart';
import '../../models/game_data.dart';
import '../../widgets/game_timer.dart';
import '../../widgets/game_result.dart';

class WordMatchScreen extends StatefulWidget {
  final WordMatchData gameData;

  WordMatchScreen({required this.gameData});

  @override
  _WordMatchScreenState createState() => _WordMatchScreenState();
}

class _WordMatchScreenState extends State<WordMatchScreen> {
  late List<String> words;
  late List<String> translations;
  Map<int, int> matches = {};
  bool isGameOver = false;
  int correctMatches = 0;
  double elapsedTime = 0;

  @override
  void initState() {
    super.initState();
    words = List.from(widget.gameData.words)..shuffle();
    translations = List.from(widget.gameData.translations)..shuffle();
  }

  void onWordTap(int wordIndex) {
    if (isGameOver) return;
    
    // 如果單詞已經匹配,取消匹配
    if (matches.containsKey(wordIndex)) {
      final translationIndex = matches[wordIndex]!;
      matches.remove(wordIndex);
      matches.remove(translationIndex);
    } 
    // 如果單詞未匹配,嘗試匹配翻譯
    else {
      final translationIndex = translations.indexOf(widget.gameData.translations[widget.gameData.words.indexOf(words[wordIndex])]);
      if (translationIndex != -1 && !matches.containsValue(translationIndex)) {
        matches[wordIndex] = translationIndex;
        matches[translationIndex] = wordIndex;

        // 如果所有單詞都已正確匹配,遊戲結束
        if (matches.length == widget.gameData.words.length * 2) {
          setState(() {
            isGameOver = true;
            correctMatches = widget.gameData.words.length;  
          });
        }
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('單詞配對')),
      body: Column(
        children: [
          // 顯示計時器
          GameTimer(onTick: (time) => elapsedTime = time),
          // 單詞和翻譯列表  
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: words.length,
                    itemBuilder: (context, index) {
                      // 根據單詞是否匹配顯示不同顏色
                      final color = matches.containsKey(index) ? Colors.green : Colors.blue;
                      return ListTile(
                        title: Text(words[index], style: TextStyle(color: color)),
                        onTap: () => onWordTap(index),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: translations.length,
                    itemBuilder: (context, index) {
                      // 根據翻譯是否匹配顯示不同顏色  
                      final wordIndex = matches[index];
                      final color = wordIndex != null ? Colors.green : Colors.blue;
                      return ListTile(
                        title: Text(translations[index], style: TextStyle(color: color)),
                        onTap: wordIndex != null ? () => onWordTap(wordIndex) : null,  
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // 遊戲結果
          if (isGameOver)
            GameResult(
              correctCount: correctMatches,
              totalCount: widget.gameData.words.length,
              elapsedTime: elapsedTime,
            ),
        ],
      ),
    );
  }
}
