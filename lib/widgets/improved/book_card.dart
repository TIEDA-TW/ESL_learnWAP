import 'package:flutter/material.dart';
import '../../models/book_model.dart';
import '../../services/storage_service.dart';
import '../../constants/book_constants.dart';

class BookCard extends StatefulWidget {
  final Book book;
  final int progress;
  final VoidCallback onTap;

  const BookCard({
    Key? key,
    required this.book,
    required this.progress,
    required this.onTap,
  }) : super(key: key);

  @override
  State<BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<BookCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        // 允許水平滑動手勢穿透此組件
        behavior: HitTestBehavior.translucent,
        // 確保點擊和滑動分開處理
        onHorizontalDragStart: (_) {}, // 空實現以確保父級的滑動事件能夠被處理
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: _isHovering 
              ? Matrix4.translationValues(0, -5, 0) 
              : Matrix4.identity(),
          // 使用固定尺寸，不再根據螢幕寬度調整
          height: 180, // 固定卡片高度
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovering ? 0.2 : 0.1),
                blurRadius: _isHovering ? 15 : 10,
                offset: Offset(0, _isHovering ? 8 : 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 書籍封面
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Stack(
                  children: [
                    // 封面圖片 - 使用多層回退機制
                    AspectRatio(
                      aspectRatio: 3 / 4,
                      child: _buildBookCover(context),
                    ),
                    
                    // 進度指示器
                    if (widget.progress > 0)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(
                          value: widget.progress / 100,
                          backgroundColor: Colors.black38,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.green,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // 書籍資訊
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // 減少邊距
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getDisplayName(),
                        style: const TextStyle(
                          fontSize: 13, // 調整字體大小
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3), // 減少間距
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 上次閱讀
                          Text(
                            '上次: 今天',
                            style: TextStyle(
                              fontSize: 9, // 調整字體大小
                              color: Colors.grey.shade600,
                            ),
                          ),
                          // 繼續閱讀按鈕
                          const Icon(
                            Icons.play_circle_fill,
                            color: Colors.blue,
                            size: 14, // 調整圖標大小
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // 智能顯示書籍名稱
  String _getDisplayName() {
    // 使用集中配置的顯示名稱方法
    return BookConstants.getBookDisplayName(widget.book.id);
  }
  
  // 多層封面圖片載入策略
  Widget _buildBookCover(BuildContext context) {
    // 定義可能的圖片路徑，按優先順序
    final imagePaths = [
      '${widget.book.imagePath}/${widget.book.id}_00-00.jpg',    // 標準路徑
      'assets/Books/${widget.book.id}/${widget.book.id}_00-00.jpg', // 絕對路徑
      'assets/Books/${widget.book.id}/cover.jpg',         // 替代命名
      'assets/images/book_placeholder.jpg',        // 通用封面
    ];
    
    return FutureBuilder<List<bool>>(
      future: _checkMultipleAssets(imagePaths),
      builder: (context, snapshot) {
        // 顯示載入指示器
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.grey[100],
            child: const Center(
              child: SizedBox(
                width: 20, 
                height: 20, 
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        
        // 找到第一個有效的圖片路徑
        if (snapshot.hasData) {
          for (int i = 0; i < snapshot.data!.length; i++) {
            if (snapshot.data![i]) {
              // 找到可用圖片，嘗試載入
              return Image.asset(
                imagePaths[i],
                fit: BoxFit.cover,
                alignment: Alignment.centerRight, // 顯示圖片右半部分
                errorBuilder: (context, error, stackTrace) {
                  print('圖片載入錯誤 ${imagePaths[i]}: $error');
                  // 嘗試下一個路徑
                  if (i + 1 < imagePaths.length) {
                    return Image.asset(
                      imagePaths[i + 1],
                      fit: BoxFit.cover,
                      alignment: Alignment.centerRight,
                      errorBuilder: (context, error, stackTrace) {
                        // 如果第二次嘗試也失敗，使用預設佔位符
                        return _buildErrorPlaceholder();
                      },
                    );
                  }
                  return _buildErrorPlaceholder();
                },
              );
            }
          }
        }
        
        // 沒有找到有效圖片，顯示錯誤佔位符
        return _buildErrorPlaceholder();
      },
    );
  }
  
  // 檢查多個資產路徑，返回每個路徑的有效性
  Future<List<bool>> _checkMultipleAssets(List<String> paths) async {
    final results = <bool>[];
    final storageService = StorageService();
    
    // 使用常數類中的教材列表
    final knownValidIds = BookConstants.enabledBooks;
    
    if (knownValidIds.contains(widget.book.id)) {
      print('${widget.book.id} 是已知有效的書籍ID');
    }
    
    for (final path in paths) {
      try {
        // 如果是已知有效的ID，且路徑格式符合預期，則假設它是有效的
        if (knownValidIds.contains(widget.book.id) && 
            (path.contains('${widget.book.id}_00-00.jpg') || path.contains('cover.jpg'))) {
          print('預設為有效路徑: $path');
          results.add(true);
          continue;
        }
        
        final exists = await storageService.checkAssetExists(path);
        results.add(exists);
        if (exists) {
          print('找到有效封面: $path');
        }
      } catch (e) {
        print('檢查資產錯誤: $path - $e');
        results.add(false);
      }
    }
    
    // 如果沒有找到任何有效路徑，至少標記最後一個（預設佔位符）為有效
    if (!results.contains(true) && results.length == paths.length) {
      print('未找到任何有效的圖片路徑，使用預設佔位符');
      results[results.length - 1] = true;
    }
    
    return results;
  }
  
  // 提取錯誤佔位符為方法，避免重複代碼
  Widget _buildErrorPlaceholder() {
    final color = _getBookSeriesColor();
    
    return Container(
      color: color.withOpacity(0.2),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book, size: 40, color: color),
            const SizedBox(height: 4),
            Text(
              _getDisplayName(),
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  // 獲取書籍系列顏色
  Color _getBookSeriesColor() {
    return BookConstants.getBookColor(widget.book.id);
  }
}
