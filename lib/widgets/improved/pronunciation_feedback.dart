import 'package:flutter/material.dart';

class PronunciationFeedback extends StatelessWidget {
  final Map<String, dynamic> result;
  final VoidCallback onClose;
  
  const PronunciationFeedback({
    Key? key,
    required this.result,
    required this.onClose,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final double score = result['score'] as double;
    final String feedback = result['feedback'] as String;
    final String? recognizedText = result['recognizedText'] as String?;
    
    // 根據分數決定顏色
    Color scoreColor;
    if (score >= 80) {
      scoreColor = Colors.green;
    } else if (score >= 60) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }
    
    return Positioned(
      right: 16,
      top: 16,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          width: 250,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '發音評估',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              // 分數顯示
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scoreColor.withOpacity(0.2),
                    border: Border.all(
                      color: scoreColor,
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      score.round().toString(),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 反饋信息
              Text(
                '反饋:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                feedback,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                ),
              ),
              
              // 識別出的文字
              if (recognizedText != null) ...[
                const SizedBox(height: 16),
                Text(
                  '識別文字:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  recognizedText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              // 建議或獎勵
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: score >= 80 
                        ? Colors.green.shade100 
                        : score >= 60 
                            ? Colors.orange.shade100 
                            : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    score >= 80 
                        ? '太棒了！繼續保持!' 
                        : score >= 60 
                            ? '很好！再加把勁！' 
                            : '再試一次，你可以的!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: score >= 80 
                          ? Colors.green.shade800 
                          : score >= 60 
                              ? Colors.orange.shade800 
                              : Colors.red.shade800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}