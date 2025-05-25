
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/book_model.dart';

class FlashcardService {
  // 從JSON文件中加載單詞數據
  Future<List<TextRegion>> loadWordsFromBook(String bookPath) async {
    // 讀取JSON文件
    String jsonString = await rootBundle.loadString(bookPath);
    List<dynamic> jsonData = json.decode(jsonString);

    // 解析JSON數據,提取單詞
    List<TextRegion> words = [];
    for (var pageData in jsonData) {
      for (var elementData in pageData['elements']) {
        if (elementData['category'] == 'Word') {
          words.add(TextRegion.fromJson(elementData));
        }
      }
    }

    return words;
  }

  // 在這裡可以添加更多與單字卡片相關的業務邏輯,如:
  // - 根據用戶的掌握程度推薦單詞
  // - 記錄用戶對每個單詞的練習情況
  // - 安排複習計劃等
}
