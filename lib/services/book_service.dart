import 'dart:convert';
import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../models/book_models_fixed.dart';
import '../config/app_config.dart';

typedef ProgressCallback = void Function(double progress, String message);

class BookService extends ChangeNotifier {
  List<BookPage> _pages = [];
  String _currentVersion = AppConfig.currentVersion;

  List<BookPage> get pages => _pages;
  String get currentVersion => _currentVersion;

  Future<void> loadBookData({ProgressCallback? onProgress}) async {
    try {
      log('BookService: Loading book data for version ${AppConfig.currentVersion}...');

      // 報告進度：開始載入
      onProgress?.call(0.1, '載入資料文件...');

      final String jsonContent =
          await rootBundle.loadString(AppConfig.bookDataPath);

      // 報告進度：解析 JSON
      onProgress?.call(0.3, '解析資料...');

      final List<dynamic> jsonData = json.decode(jsonContent);

      // 報告進度：轉換數據
      onProgress?.call(0.5, '處理資料...');

      // 確保jsonData是List<dynamic>格式
      if (jsonData is! List<dynamic>) {
        throw TypeError();
      }

      // 將資料按照圖片分組
      Map<String, List<dynamic>> groupedData = {};
      for (var item in jsonData) {
        if (item is Map<String, dynamic>) {
          String imageName = item['Image'] ?? '';
          if (imageName.isNotEmpty) {
            if (!groupedData.containsKey(imageName)) {
              groupedData[imageName] = [];
            }
            groupedData[imageName]!.add(item);
          }
        }
      }

      // 轉換為BookPage列表
      List<BookPage> tempPages = [];
      groupedData.forEach((imageName, elements) {
        List<BookElement> bookElements = [];

        for (var element in elements) {
          // 轉換座標
          Coordinates coordinates = Coordinates(
            x1: (element['X1'] as num).toDouble(),
            y1: (element['Y1'] as num).toDouble(),
            x2: (element['X2'] as num).toDouble(),
            y2: (element['Y2'] as num).toDouble(),
          );

          // 確定類別
          ElementCategory category;
          switch (element['Category']) {
            case 'Word':
              category = ElementCategory.Word;
              break;
            case 'Sentence':
              category = ElementCategory.Sentence;
              break;
            case 'FullText':
              category = ElementCategory.FullText;
              break;
            default:
              category = ElementCategory.Word;
          }

          // 創建BookElement
          BookElement bookElement = BookElement(
            text: element['Text'] ?? '',
            category: category,
            coordinates: coordinates,
            audioFile: element['English_Audio_File'] ?? '', // JSON 轉換：English_Audio_File -> audioFile
            translation: element['中文翻譯'],
            zhAudioFile: element['Chinese_Audio_File'], // JSON 轉換：Chinese_Audio_File -> zhAudioFile
            isValid: true,
          );

          bookElements.add(bookElement);
        }

        // 創建BookPage
        BookPage bookPage = BookPage(
          image: imageName,
          elements: bookElements,
        );

        tempPages.add(bookPage);
      });

      // 按照頁碼排序
      tempPages.sort((a, b) {
        // 提取頁碼
        int getPageNumber(String imageName) {
          // 格式為 V1_00-00.jpg 或 V1_01-02.jpg
          final parts = imageName.split('_');
          if (parts.length > 1) {
            final pageInfo = parts[1].split('.').first;
            final firstPage = pageInfo.split('-').first;
            return int.tryParse(firstPage) ?? 0;
          }
          return 0;
        }

        return getPageNumber(a.image).compareTo(getPageNumber(b.image));
      });

      // 報告進度：完成載入
      onProgress?.call(0.7, '載入完成');

      _pages = tempPages;
      _currentVersion = AppConfig.currentVersion;

      notifyListeners();

      log('BookService: Loaded ${_pages.length} pages for version $_currentVersion');
    } catch (e, stackTrace) {
      log('BookService: Error loading book data',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  List<BookElement> getPageElements(int pageIndex, String category) {
    if (pageIndex < 0 || pageIndex >= _pages.length) {
      return [];
    }
    return _pages[pageIndex]
        .elements
        .where((element) => element.category == category)
        .toList();
  }

  String? getImagePath(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= _pages.length) {
      return null;
    }
    return '${AppConfig.booksPath}/${_pages[pageIndex].image}';
  }

  String getAudioPath(String audioFileName, {bool isChinese = false}) {
    if (audioFileName.isEmpty) return '';

    // 根據語言選擇音檔路徑
    final basePath = isChinese ? AppConfig.zhAudioPath : AppConfig.enAudioPath;
    return '$basePath/$audioFileName';
  }

  bool canGoNext(int currentIndex) => currentIndex < _pages.length - 1;
  bool canGoPrevious(int currentIndex) => currentIndex > 0;
}
