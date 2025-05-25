class Book {
  final String id;
  final String name;
  final String dataPath;
  final String imagePath;
  final String audioPath; // 書籍音檔基礎路徑，用於構建完整音檔路徑
  
  Book({
    required this.id,
    required this.name,
    required this.dataPath,
    required this.imagePath,
    required this.audioPath,
  });

  // 根據音檔檔名構建完整的音檔路徑
  String getAudioPath(String audioFile) {
    return audioPath + '/' + audioFile;
  }

  String getImagePath(String imageFile) {
    return imagePath + '/' + imageFile;
  }
}

class TextRegion {
  final String text;
  final String category;
  final String audioFile; // 音檔檔名，統一使用 audioFile 欄位名稱
  final Map<String, double> position;
  String? translation; // 修改: 變更為可變屬性
  
  TextRegion({
    required this.text,
    required this.category,
    required this.audioFile,
    required this.position,
    this.translation,
  });
  
  // 從JSON創建實例
  factory TextRegion.fromJson(Map<String, dynamic> json) {
    return TextRegion(
      text: json['text'] ?? '',
      category: json['category'] ?? '',
      audioFile: json['audioFile'] ?? '',
      position: {
        'x1': (json['coordinates']['x1'] ?? 0).toDouble(),
        'y1': (json['coordinates']['y1'] ?? 0).toDouble(),
        'x2': (json['coordinates']['x2'] ?? 0).toDouble(),
        'y2': (json['coordinates']['y2'] ?? 0).toDouble(),
      },
      translation: json['translation'],
    );
  }
  
  // 轉換為JSON
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'category': category,
      'audioFile': audioFile,
      'coordinates': {
        'x1': position['x1'],
        'y1': position['y1'],
        'x2': position['x2'],
        'y2': position['y2'],
      },
      'translation': translation,
    };
  }
}

class BookPage {
  final String image;
  final List<TextRegion> elements;
  
  BookPage({
    required this.image,
    required this.elements,
  });
  
  // 從JSON創建實例
  factory BookPage.fromJson(Map<String, dynamic> json) {
    final elements = (json['elements'] as List)
        .map((e) => TextRegion.fromJson(e))
        .toList();
    
    return BookPage(
      image: json['image'] ?? '',
      elements: elements,
    );
  }
  
  // 轉換為JSON
  Map<String, dynamic> toJson() {
    return {
      'image': image,
      'elements': elements.map((e) => e.toJson()).toList(),
    };
  }
}