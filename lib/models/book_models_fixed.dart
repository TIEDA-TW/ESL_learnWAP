enum ElementCategory {
  Sentence,
  Word,
  FullText,
}

class Coordinates {
  final double x1;
  final double y1;
  final double x2;
  final double y2;

  Coordinates({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });

  factory Coordinates.fromJson(Map<String, dynamic> json) {
    return Coordinates(
      x1: (json['x1'] as num).toDouble(),
      y1: (json['y1'] as num).toDouble(),
      x2: (json['x2'] as num).toDouble(),
      y2: (json['y2'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x1': x1,
      'y1': y1,
      'x2': x2,
      'y2': y2,
    };
  }

  bool isValid() => x1 >= 0 && y1 >= 0 && x1 <= x2 && y1 <= y2;
}

class BookPage {
  final String image;
  final List<BookElement> elements;

  BookPage({required this.image, required this.elements});

  bool get isValid => elements.every((element) => element.isContentValid);

  factory BookPage.fromJson(Map<String, dynamic> json) {
    return BookPage(
      image: json['image'],
      elements: (json['elements'] as List)
          .map((e) => BookElement.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image': image,
      'elements': elements.map((e) => e.toJson()).toList(),
    };
  }
}

class BookElement {
  final String text;
  final ElementCategory category;
  final Coordinates coordinates;
  
  // 音檔欄位命名規則說明：
  // - audioFile: 英文音檔檔名 (統一內部表示，對應 JSON 中的 English_Audio_File)
  // - zhAudioFile: 中文音檔檔名 (統一內部表示，對應 JSON 中的 Chinese_Audio_File)
  // 注意：JSON 資料使用描述性名稱，程式碼使用簡潔名稱，在 fromJson() 中進行轉換
  final String audioFile;
  final String? translation; // 中文翻譯
  final String? zhAudioFile; // 中文音檔路徑
  final bool isValid;

  BookElement({
    required this.text,
    required this.category,
    required this.coordinates,
    required this.audioFile,
    this.translation,
    this.zhAudioFile,
    this.isValid = true,
  });

  // 從中文音訊檔名提取翻譯文字
  static String? _extractTranslationFromAudioFile(String? audioFileName) {
    if (audioFileName == null || !audioFileName.startsWith('zh_')) {
      return null;
    }
    
    // 去除前綴 'zh_' 和副檔名 '.mp3'
    String translationText = audioFileName.substring(3);
    if (translationText.toLowerCase().endsWith('.mp3')) {
      translationText = translationText.substring(0, translationText.length - 4);
    }
    
    return translationText;
  }

  factory BookElement.fromJson(Map<String, dynamic> json) {
    // 獲取中文音檔路徑
    final zhAudioFile = json['Chinese_Audio_File'] ?? json['zhAudioFile'];
    
    // 從中文音檔名提取翻譯文字
    final extractedTranslation = _extractTranslationFromAudioFile(zhAudioFile);
    
    // 使用提取的翻譯，如果提取失敗則使用原有翻譯
    final translation = extractedTranslation ?? json['中文翻譯'] ?? json['translation'];
    
    return BookElement(
      text: json['Text'] ?? json['text'] ?? '',
      category: ElementCategory.values.firstWhere(
        (e) =>
            e.toString() ==
            'ElementCategory.${json['Category'] ?? json['category']}',
        orElse: () => ElementCategory.Word,
      ),
      coordinates: json['coordinates'] != null
          ? Coordinates.fromJson(json['coordinates'])
          : Coordinates(
              x1: (json['X1'] as num?)?.toDouble() ?? 0,
              y1: (json['Y1'] as num?)?.toDouble() ?? 0,
              x2: (json['X2'] as num?)?.toDouble() ?? 0,
              y2: (json['Y2'] as num?)?.toDouble() ?? 0,
            ),
      audioFile: json['English_Audio_File'] ?? json['audioFile'] ?? '', // 優先使用 JSON 中的 English_Audio_File，回退到 audioFile
      translation: translation,
      zhAudioFile: zhAudioFile, // 中文音檔：Chinese_Audio_File -> zhAudioFile
      isValid: json['isValid'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'category': category.toString().split('.').last,
      'coordinates': coordinates.toJson(),
      'audioFile': audioFile,
      'translation': translation,
      'zhAudioFile': zhAudioFile,
      'isValid': isValid,
    };
  }

  // 检查内容是否有效（不与字段冲突）
  bool get isContentValid =>
      text.isNotEmpty && coordinates.isValid() && audioFile.isNotEmpty;
}
