import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart'; // Required for Rect
import '../models/book_model.dart';
import '../models/game_data.dart';
import 'storage_service.dart';

class GameService {
  final StorageService _storageService = StorageService();

  // 根據書籍生成單詞配對遊戲數據
  Future<WordMatchData> generateWordMatchData(Book book) async {
    try {
      // 從書籍數據中提取單詞和翻譯
      final bookData = await _loadBookData(book.dataPath);
      final words = <String>[];
      final translations = <String>[];

      for (final page in bookData['pages']) {
        for (final region in page['regions']) {
          if (region['type'] == 'word') {
            words.add(region['text']);
            translations.add(region['translation'] ?? '');
          }
        }
      }

      if (words.isEmpty) {
        throw Exception('書籍中沒有找到足夠的單詞');
      }

      // 確保單詞和翻譯數量相同
      final minLength = words.length < translations.length ? words.length : translations.length;
      words.removeRange(minLength, words.length);
      translations.removeRange(minLength, translations.length);

      return WordMatchData(
        words: words,
        translations: translations,
      );
    } catch (e) {
      debugPrint('生成單詞配對遊戲數據失敗: $e');
      rethrow;
    }
  }
  
  // 根據書籍生成句子填空遊戲數據
  Future<SentenceFillData> generateSentenceFillData(Book book) async {
    try {
      // 從書籍數據中提取句子
      final bookData = await _loadBookData(book.dataPath);
      final sentences = <String>[];
      final options = <String>[];

      for (final page in bookData['pages']) {
        for (final region in page['regions']) {
          if (region['type'] == 'sentence') {
            sentences.add(region['text']);
            // 提取句子中的關鍵詞作為選項
            final words = region['text'].split(' ');
            options.addAll(words.where((word) => word.length > 3));
          }
        }
      }

      if (sentences.isEmpty) {
        throw Exception('書籍中沒有找到足夠的句子');
      }

      // 選擇一個隨機句子
      final random = sentences[DateTime.now().millisecondsSinceEpoch % sentences.length];
      
      // 確保選項不重複
      final uniqueOptions = options.toSet().toList();

      return SentenceFillData(
        sentence: random,
        options: uniqueOptions,
      );
    } catch (e) {
      debugPrint('生成句子填空遊戲數據失敗: $e');
      rethrow;
    }
  }

  // 根據書籍生成圖片找茬遊戲數據
  Future<PictureDiffData> generatePictureDiffData(Book book) async {
    try {
      // 從書籍數據中提取圖片
      final bookData = await _loadBookData(book.dataPath);
      final images = <String>[];

      for (final page in bookData['pages']) {
        if (page['image'] != null) {
          images.add(page['image']);
        }
      }

      if (images.isEmpty) {
        throw Exception('書籍中沒有找到足夠的圖片');
      }

      // 選擇兩張圖片進行比較
      final random = DateTime.now().millisecondsSinceEpoch % images.length;
      final originalImage = images[random];
      final modifiedImage = images[(random + 1) % images.length];

      // For demonstration, we'll use fixed image paths and predefined diff areas
      // In a real app, these would be specific to the book or dynamically generated.
      // Ensure these image paths exist in your assets.
      // Using placeholder paths for now.
      const String demoOriginalImage = 'assets/images/pic_diff_original.png'; // Replace with actual asset
      const String demoModifiedImage = 'assets/images/pic_diff_modified.png'; // Replace with actual asset

      // Sample difference areas (Rects). These are just examples.
      // You'll need to define these based on your actual images.
      // Rect.fromLTWH(left, top, width, height)
      final List<Rect> sampleDiffAreas = [
        Rect.fromLTWH(50, 50, 30, 30),   // Example diff 1
        Rect.fromLTWH(120, 100, 40, 25), // Example diff 2
        Rect.fromLTWH(200, 150, 20, 50), // Example diff 3
        Rect.fromLTWH(80, 220, 50, 30),  // Example diff 4
        Rect.fromLTWH(150, 20, 35, 35),  // Example diff 5
      ];

      // To make it more dynamic, let's pick a few random ones if we had a larger list
      // final random = Random();
      // sampleDiffAreas.shuffle(random);
      // final selectedAreas = sampleDiffAreas.take(random.nextInt(3) + 3).toList(); // Take 3 to 5 diffs

      // For now, we use all sample areas
      final selectedAreas = sampleDiffAreas;


      // Check if book has specific images for picture diff, otherwise use demo
      // This part remains conceptual as we don't have that data structure in BookModel
      String originalImageToUse = demoOriginalImage;
      String modifiedImageToUse = demoModifiedImage;
      List<Rect> diffAreasToUse = selectedAreas;

      // Example: if book.pictureDiffGameAssets are available, use them
      // if (book.pictureDiffImages != null && book.pictureDiffImages.isNotEmpty) {
      //   originalImageToUse = book.pictureDiffImages[0].original;
      //   modifiedImageToUse = book.pictureDiffImages[0].modified;
      //   diffAreasToUse = book.pictureDiffImages[0].diffs;
      // }


      return PictureDiffData(
        originalImage: originalImageToUse, // Use image from book or demo
        modifiedImage: modifiedImageToUse, // Use image from book or demo
        diffAreas: diffAreasToUse, // Use diffs from book or demo
      );
    } catch (e) {
      debugPrint('生成圖片找茬遊戲數據失敗: $e');
      // Fallback to placeholder data if generation fails
      return PictureDiffData(
        originalImage: 'assets/images/pic_diff_original.png', // Ensure this placeholder exists
        modifiedImage: 'assets/images/pic_diff_modified.png', // Ensure this placeholder exists
        diffAreas: [
          Rect.fromLTWH(10, 10, 20, 20),
          Rect.fromLTWH(50, 50, 30, 30),
        ],
      );
    }
  }

  // 載入書籍數據
  Future<Map<String, dynamic>> _loadBookData(String dataPath) async {
    try {
      final jsonString = await _storageService.loadAsset(dataPath);
      final data = jsonDecode(jsonString);
      if (data is Map<String, dynamic> && data.containsKey('pages')) {
        return data;
      } else {
        throw Exception('書籍資料格式錯誤，缺少 pages 欄位');
      }
    } catch (e) {
      debugPrint('載入書籍數據失敗: $e');
      rethrow;
    }
  }
}
