import 'package:flutter/material.dart';

class VocabFlashcard extends StatelessWidget {
  final String word;
  final String translation;
  final String example;
  final String exampleTranslation;
  final bool showTranslation;
  final VoidCallback onPlay;
  final int speechRateIndex;
  final List<String> speechRateLabels;
  final VoidCallback onSpeechRateToggle;
  
  const VocabFlashcard({
    Key? key,
    required this.word,
    required this.translation,
    required this.example,
    required this.exampleTranslation,
    required this.showTranslation,
    required this.onPlay,
    required this.speechRateIndex,
    required this.speechRateLabels,
    required this.onSpeechRateToggle,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: showTranslation
                ? [Colors.orange.shade50, Colors.orange.shade100]
                : [Colors.blue.shade50, Colors.blue.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 單字或翻譯
              Text(
                showTranslation ? translation : word,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              // 顯示模式指示
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: showTranslation
                      ? Colors.orange.shade200
                      : Colors.blue.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  showTranslation ? '中文' : '英文',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: showTranslation
                        ? Colors.orange.shade800
                        : Colors.blue.shade800,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // 播放按鈕與語速切換
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.volume_up),
                    onPressed: onPlay,
                    iconSize: 36,
                    color: Colors.blue,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.speed),
                    tooltip: '語速：' + speechRateLabels[speechRateIndex],
                    onPressed: onSpeechRateToggle,
                    iconSize: 36,
                    color: Colors.blue,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // 例句
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '例句:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      example,
                      style: const TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      exampleTranslation,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 提示
              Text(
                '點擊卡片翻轉',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}