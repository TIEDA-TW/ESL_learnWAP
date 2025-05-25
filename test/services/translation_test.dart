// 用於測試翻譯服務的簡單程式
import 'package:flutter/material.dart';
import 'translation_service.dart';

// 此檔案用於驗證翻譯服務是否正確加載了從 Book_data 目錄的翻譯
// 可以在需要測試時引入使用

class TranslationTester {
  static Future<void> testTranslation(BuildContext context) async {
    try {
      // 初始化翻譯服務
      final translationService = TranslationService();
      await translationService.initialize();
      
      // 獲取全部翻譯項目數量
      final translationCount = (translationService as dynamic)._translationData.length;
      
      // 測試幾個英文單詞或短語
      final testWords = ['ALICE', 'ESL', 'Beginners'];
      final testResults = <String, String>{};
      
      for (var word in testWords) {
        testResults[word] = translationService.translate(word);
      }
      
      // 顯示結果
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('翻譯測試結果'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('總共載入了 $translationCount 個翻譯項目'),
              SizedBox(height: 10),
              ...testWords.map((word) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: [
                      TextSpan(
                        text: '$word: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: testResults[word] ?? '未找到翻譯'),
                    ],
                  ),
                ),
              )).toList(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('關閉'),
            ),
          ],
        ),
      );
    } catch (e) {
      // 顯示錯誤訊息
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('翻譯測試失敗'),
          content: Text('發生錯誤: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('關閉'),
            ),
          ],
        ),
      );
    }
  }
}