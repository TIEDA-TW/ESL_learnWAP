import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
// 只導入一個模型文件，避免衝突
// import '../models/book_model.dart';
import '../models/book_models_fixed.dart'; // 導入包含BookElement、Coordinates和ElementCategory的檔案
import '../models/user_progress.dart';
import '../constants/book_constants.dart';
import 'dart:js' as js;

class StorageService {
  // 單例模式
  static final StorageService _instance = StorageService._internal();
  
  factory StorageService() {
    return _instance;
  }
  
  StorageService._internal();
  
  // 載入資源文件
  Future<String> loadAsset(String path) async {
    try {
      return await rootBundle.loadString(path);
    } catch (e) {
      debugPrint('載入資源文件失敗: $e');
      throw Exception('無法載入資源文件: $e');
    }
  }
  
  // 載入書籍資料
  Future<List<BookPage>> loadBookData(String dataPath) async {
    try {
      final String jsonString = await loadAsset(dataPath);
      final dynamic decodedData = json.decode(jsonString);
      
      final List<BookPage> pages = [];
      
      // 處理兩種可能的JSON格式：List或Map
      if (decodedData is List) {
        // 直接處理列表格式的數據
        Map<String, List<dynamic>> groupedData = {};
        
        // 將數據按照圖片分組
        for (var item in decodedData) {
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
        
        // 為每個圖片創建一個頁面
        groupedData.forEach((imageName, elements) {
          List<BookElement> bookElements = [];
          
          for (var element in elements) {
            // 創建坐標
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
              // 音檔欄位轉換：JSON 中的 English_Audio_File -> 程式碼中的 audioFile
              audioFile: element['English_Audio_File'] ?? '',
              translation: element['中文翻譯'],
              // 音檔欄位轉換：JSON 中的 Chinese_Audio_File -> 程式碼中的 zhAudioFile
              zhAudioFile: element['Chinese_Audio_File'],
              isValid: true,
            );
            
            bookElements.add(bookElement);
          }
          
          // 創建BookPage
          pages.add(BookPage(
            image: imageName,
            elements: bookElements,
          ));
        });
        
        // 按照頁碼排序
        pages.sort((a, b) {
          // 提取頁碼 (格式為 V1_00-00.jpg 或 V1_01-02.jpg)
          int getPageNumber(String imageName) {
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
      } else if (decodedData is Map<String, dynamic> && decodedData.containsKey('pages')) {
        // 處理Map格式的數據
        for (var pageData in decodedData['pages']) {
          pages.add(BookPage.fromJson(pageData));
        }
      } else {
        throw FormatException('無效的數據格式');
      }
      
      return pages;
    } catch (e) {
      debugPrint('載入書籍資料失敗: $e');
      throw Exception('無法載入書籍資料: $e');
    }
  }
  
  // 保存使用者進度
  Future<void> saveUserProgress(UserProgress userProgress) async {
    if (kIsWeb) {
      // Web平台暫時不支持保存進度
      return;
    }
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/user_progress.json');
      
      final jsonData = json.encode(userProgress.toJson());
      await file.writeAsString(jsonData);
    } catch (e) {
      debugPrint('保存使用者進度失敗: $e');
      throw Exception('無法保存使用者進度: $e');
    }
  }
  
  // 載入使用者進度
  Future<UserProgress?> loadUserProgress() async {
    if (kIsWeb) {
      // Web平台暫時不支持載入進度
      return null;
    }
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/user_progress.json');
      
      if (!await file.exists()) {
        return null;
      }
      
      final jsonString = await file.readAsString();
      final Map<String, dynamic> data = json.decode(jsonString);
      
      return UserProgress.fromJson(data);
    } catch (e) {
      debugPrint('載入使用者進度失敗: $e');
      return null;
    }
  }
  
  // 保存錄音文件
  Future<String> saveRecording(String tempPath, String userId, String bookId, String elementId) async {
    if (kIsWeb) {
      // Web平台暫時不支持保存錄音
      return tempPath;
    }
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${directory.path}/recordings/$userId/$bookId');
      
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newPath = '${recordingsDir.path}/${elementId}_$timestamp.m4a';
      
      final tempFile = File(tempPath);
      await tempFile.copy(newPath);
      
      return newPath;
    } catch (e) {
      debugPrint('保存錄音文件失敗: $e');
      throw Exception('無法保存錄音文件: $e');
    }
  }
  
  // 獲取錄音文件列表
  Future<List<String>> getRecordings(String userId, String bookId, String elementId) async {
    if (kIsWeb) {
      // Web平台暫時不支持獲取錄音列表
      return [];
    }
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${directory.path}/recordings/$userId/$bookId');
      
      if (!await recordingsDir.exists()) {
        return [];
      }
      
      final files = await recordingsDir.list().toList();
      return files
          .whereType<File>()
          .where((file) => file.path.contains(elementId))
          .map((file) => file.path)
          .toList();
    } catch (e) {
      debugPrint('獲取錄音文件列表失敗: $e');
      return [];
    }
  }
  
  // 檢查資產是否存在
  Future<bool> checkAssetExists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (e) {
      print('資產不存在: $assetPath, 錯誤: $e');
      return false;
    }
  }
  
  // 獲取所有有效的書籍ID
  Future<List<String>> getAllValidBookIds() async {
    try {
      final Set<String> bookIds = <String>{};
      
      // 策略 1: 使用 AssetManifest.json
      try {
        final manifestContent = await rootBundle.loadString('AssetManifest.json');
        final Map<String, dynamic> manifestMap = json.decode(manifestContent);
        
        final pattern = RegExp(r'assets/Book_data/(.+)_book_data\.json');
        
        for (final key in manifestMap.keys) {
          final match = pattern.firstMatch(key);
          if (match != null) {
            final id = match.group(1);
            if (id != null) {
              bookIds.add(id);
              print('從 AssetManifest 找到書籍ID: $id');
            }
          }
        }
      } catch (e) {
        print('使用 AssetManifest 獲取書籍ID失敗: $e');
      }
      
      // 策略 2: 如果 AssetManifest 方法沒有找到足夠的 ID，使用硬編碼列表
      if (bookIds.isEmpty || bookIds.length < 3) {
        print('從 AssetManifest 找到的ID不足 (${bookIds.length})，使用硬編碼列表');
        final hardcodedIds = await getHardcodedBookIds();
        bookIds.addAll(hardcodedIds);
      }
      
      // 策略 3: 在 Web 環境中，使用 JavaScript 檢查資源
      if (kIsWeb) {
        try {
          print('在 Web 環境中使用 JavaScript 驗證資源');
          // 使用常數類中的教材列表
          final allPossibleIds = BookConstants.enabledBooks;
          
          // 直接添加所有可能的ID，避免依賴於JavaScript檢查
          for (final id in allPossibleIds) {
            if (!bookIds.contains(id)) {
              bookIds.add(id);
              print('Web環境中添加可能的有效資源: $id');
            }
          }
          
          // 如果 JS 功能可用，嘗試使用它，但不依賴於它
          try {
            if (js.context.hasProperty('checkResourceExists')) {
              print('找到 JS 資源檢查函數，但不使用它進行驗證');
            }
          } catch (jsError) {
            print('JavaScript 互操作錯誤 (忽略): $jsError');
          }
        } catch (e) {
          print('JavaScript 資源驗證失敗 (忽略): $e');
        }
      }
      
      // 最終的排序
      final sortedIds = bookIds.toList()..sort((a, b) {
        // 優先按系列排序，然後按編號排序
        String seriesA = a.substring(0, 1);
        String seriesB = b.substring(0, 1);
        
        if (seriesA != seriesB) {
          // V 系列優先，然後是 P 系列，最後是 T 系列
          if (seriesA == 'V') return -1;
          if (seriesB == 'V') return 1;
          if (seriesA == 'P') return -1;
          if (seriesB == 'P') return 1;
        }
        
        // 同系列按編號排序
        try {
          final numA = int.tryParse(a.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
          final numB = int.tryParse(b.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
          return numA.compareTo(numB);
        } catch (e) {
          return a.compareTo(b);
        }
      });
      
      print('最終獲取到 ${sortedIds.length} 個有效的書籍ID: ${sortedIds.join(", ")}');
      return sortedIds;
    } catch (e) {
      print('獲取有效書籍ID失敗: $e');
      // 發生錯誤時仍返回硬編碼列表
      return await getHardcodedBookIds();
    }
  }
  
  // 直接提供固定的書籍ID列表，確保所有可用書籍都能被載入
  Future<List<String>> getHardcodedBookIds() async {
    final List<String> bookIds = BookConstants.enabledBooks;
    final List<String> validIds = [];
    
    for (final id in bookIds) {
      try {
        final dataPath = BookConstants.getBookDataPath(id); // 使用常數方法
        final coverPath = BookConstants.getBookCoverPath(id); // 使用常數方法
        
        final hasData = await checkAssetExists(dataPath);
        if (hasData) {
          print('找到有效書籍資料: $dataPath');
          validIds.add(id);
        }
      } catch (e) {
        print('檢查書籍ID $id 時出錯: $e');
      }
    }
    
    return validIds;
  }

  // 加載教材資源的完整方法 - 結合硬編碼和動態掃描
  Future<List<String>> getCompleteBookIds() async {
    try {
      // 先嘗試使用動態方法
      final dynamicIds = await getAllValidBookIds();
      if (dynamicIds.isNotEmpty) {
        print('使用動態方法找到 ${dynamicIds.length} 個書籍: ${dynamicIds.join(", ")}');
        return dynamicIds;
      }
      
      // 如果動態方法失敗，使用硬編碼列表
      final hardcodedIds = await getHardcodedBookIds();
      print('使用硬編碼列表找到 ${hardcodedIds.length} 個書籍: ${hardcodedIds.join(", ")}');
      return hardcodedIds;
    } catch (e) {
      print('獲取書籍ID時出錯: $e');
      return [];
    }
  }
  
  // 驗證書籍資源完整性
  Future<Map<String, bool>> validateBookResources(String bookId) async {
    final results = <String, bool>{};
    
    try {
      // 檢查數據文件
      final dataPath = BookConstants.getBookDataPath(bookId); // 使用常數方法
      results['data'] = await checkAssetExists(dataPath);
      
      // 嘗試載入書籍數據
      if (results['data'] == true) {
        final bookData = await loadBookData(dataPath);
        
        // 檢查封面圖片
        final coverPath = BookConstants.getBookCoverPath(bookId); // 使用常數方法
        results['cover'] = await checkAssetExists(coverPath);
        
        // 檢查內頁圖片 (抽樣檢查第一頁)
        if (bookData.isNotEmpty) {
          final firstPageImage = bookData.first.image;
          final imagePath = '${BookConstants.getBookImagePath(bookId)}/$firstPageImage'; // 使用常數方法
          results['pages'] = await checkAssetExists(imagePath);
        } else {
          results['pages'] = false;
        }
      }
    } catch (e) {
      print('驗證書籍 $bookId 資源時出錯: $e');
      results['error'] = true;
    }
    
    return results;
  }
}