import 'package:flutter/material.dart';
import '../../models/book_model.dart';
import '../../services/translation_service.dart';
import '../../services/improved/tts_service.dart';
import '../../services/user_service_improved.dart';

class ImprovedInteractiveTextRegion extends StatefulWidget {
  final TextRegion region;
  final double scale;
  final Offset offset;
  final Function(TextRegion) onTap;
  final bool showTranslation;
  final bool isHighlighted;
  final bool isAutoplay;
  final AnimationController pulseAnimation;
  final double speechRate;
  
  const ImprovedInteractiveTextRegion({
    Key? key,
    required this.region,
    required this.scale,
    required this.offset,
    required this.onTap,
    required this.pulseAnimation,
    this.showTranslation = false,
    this.isHighlighted = false,
    this.isAutoplay = false,
    this.speechRate = 0.7, // 預設語速
  }) : super(key: key);

  @override
  State<ImprovedInteractiveTextRegion> createState() => _ImprovedInteractiveTextRegionState();
}

class _ImprovedInteractiveTextRegionState extends State<ImprovedInteractiveTextRegion> {
  bool _isHovered = false;
  late TranslationService _translationService;
  String? _cachedTranslation;
  
  @override
  void initState() {
    super.initState();
    _translationService = TranslationService();
    _loadTranslation();
  }
  
  @override
  void didUpdateWidget(ImprovedInteractiveTextRegion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.region.text != widget.region.text || 
        oldWidget.showTranslation != widget.showTranslation) {
      _loadTranslation();
    }
  }
  
  // 載入翻譯
  Future<void> _loadTranslation() async {
    if (widget.showTranslation && widget.region.text.isNotEmpty) {
      // 使用現有翻譯或從翻譯服務獲取
      _cachedTranslation = widget.region.translation ?? 
                           _translationService.translate(widget.region.text);
      
      if (mounted) {
        setState(() {});
      }
    }
  }
  
  // 計算縮放後的位置
  Rect _getScaledPosition() {
    final position = widget.region.position;
    final x1 = position['x1']! * widget.scale + widget.offset.dx;
    final y1 = position['y1']! * widget.scale + widget.offset.dy;
    final x2 = position['x2']! * widget.scale + widget.offset.dx;
    final y2 = position['y2']! * widget.scale + widget.offset.dy;
    
    return Rect.fromLTRB(x1, y1, x2, y2);
  }
  
  @override
  Widget build(BuildContext context) {
    final rect = _getScaledPosition();
    
    // 自動播放模式下的脈衝動畫
    final pulseValue = widget.isAutoplay 
        ? Tween<double>(begin: 0, end: 5).animate(widget.pulseAnimation).value
        : 0.0;
    
    // 邊框顏色
    Color borderColor;
    if (widget.isAutoplay) {
      borderColor = Colors.red.withOpacity(0.6);
    } else if (widget.isHighlighted) {
      borderColor = Colors.red.withOpacity(0.6);
    } else if (_isHovered) {
      borderColor = Colors.blue.withOpacity(0.6);
    } else {
      borderColor = Colors.blue.withOpacity(0.3);
    }
    
    // 背景顏色 - 更透明
    Color backgroundColor;
    if (widget.isAutoplay) {
      backgroundColor = Colors.yellow.withOpacity(0.1);
    } else if (widget.isHighlighted) {
      backgroundColor = Colors.yellow.withOpacity(0.1);
    } else if (_isHovered) {
      backgroundColor = Colors.yellow.withOpacity(0.05);
    } else {
      backgroundColor = Colors.transparent;
    }
    
    // 顯示的翻譯文本
    final translationText = _cachedTranslation ?? 
                           (widget.region.translation ?? widget.region.text);
    
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      left: rect.left - pulseValue,
      top: rect.top - pulseValue,
      width: rect.width + (pulseValue * 2),
      height: rect.height + (pulseValue * 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: () {
            // 點擊時顯示翻譯對話框
            if (widget.showTranslation) {
              _showTranslationDialog(context, widget.region.text, translationText);
            }
            widget.onTap(widget.region);
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: borderColor,
                width: widget.isAutoplay || widget.isHighlighted ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(4),
              color: backgroundColor,
              boxShadow: widget.isAutoplay 
                  ? [
                      BoxShadow(
                        color: Colors.yellow.withOpacity(0.3),
                        blurRadius: 10 + pulseValue * 2,
                        spreadRadius: pulseValue,
                      )
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }
  
  // 用 Text + SingleChildScrollView，字體根據螢幕寬度自適應（無 AutoSizeText）
  void _showTranslationDialog(BuildContext context, String originalText, String translatedText) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double fontSize = screenWidth < 500 ? 28 : 56;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // 語音自動播放：Dialog 彈出後自動播放英文，播完再播中文
        Future.delayed(Duration.zero, () async {
          final tts = TtsService();
          double rate = widget.speechRate;
          String? voice;
          // 取得語音偏好（可依需求調整，這裡預設女聲）
          try {
            final userService = ImprovedUserService();
            voice = await userService.getPreferredVoice();
          } catch (_) {}
          // 英文語音
          await tts.speak(originalText, rate: rate, lang: 'en-US', voice: voice);
          // 中文語音
          await tts.speak(translatedText, rate: rate, lang: 'zh-TW', voice: voice);
        });
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('翻譯', style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('英文原文:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: fontSize)),
                Text(originalText, style: TextStyle(fontSize: fontSize)),
                SizedBox(height: fontSize * 0.5),
                Text('中文翻譯:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: fontSize)),
                Text(translatedText, style: TextStyle(fontSize: fontSize)),
              ],
            ),
          ),
        );
      },
    );
  }
}