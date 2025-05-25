import 'package:flutter/material.dart';
import '../../models/vocabulary_model.dart';

class FlashCard extends StatefulWidget {
  final VocabularyItem word;
  final VoidCallback onPlayAudio;
  final VoidCallback onMarkMastered;
  
  const FlashCard({
    Key? key,
    required this.word,
    required this.onPlayAudio,
    required this.onMarkMastered,
  }) : super(key: key);

  @override
  State<FlashCard> createState() => _FlashCardState();
}

class _FlashCardState extends State<FlashCard> with SingleTickerProviderStateMixin {
  bool _showDetails = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _toggleCardDetails() {
    setState(() {
      _showDetails = !_showDetails;
      
      if (_showDetails) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleCardDetails,
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          height: MediaQuery.of(context).size.height * 0.55,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(_animation.value * 3.14),
                alignment: Alignment.center,
                child: _animation.value < 0.5
                    ? _buildFrontCard()
                    : Transform(
                        transform: Matrix4.identity()..rotateY(3.14),
                        alignment: Alignment.center,
                        child: _buildBackCard(),
                      ),
              );
            },
          ),
        ),
      ),
    );
  }
  
  Widget _buildFrontCard() {
    final difficultyColor = widget.word.difficulty == 'Easy'
        ? Colors.green
        : widget.word.difficulty == 'Medium'
            ? Colors.orange
            : Colors.red;
    
    return Column(
      children: [
        // 卡片頂部
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 難度標籤
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: difficultyColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: difficultyColor),
                ),
                child: Text(
                  widget.word.difficulty,
                  style: TextStyle(
                    color: difficultyColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              // 類別標籤
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue),
                ),
                child: Text(
                  widget.word.category,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // 單字內容
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 單字
                Text(
                  widget.word.word,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // 單字圖片
                if (widget.word.imageFile != null)
                  Expanded(
                    child: Image.asset(
                      widget.word.imageFile!,
                      fit: BoxFit.contain,
                    ),
                  ),
                
                const SizedBox(height: 20),
                
                // 按鈕列
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 播放發音按鈕
                    IconButton(
                      onPressed: widget.onPlayAudio,
                      icon: const Icon(Icons.volume_up),
                      color: Colors.blue,
                      iconSize: 32,
                      tooltip: '播放發音',
                    ),
                    
                    const SizedBox(width: 20),
                    
                    // 標記掌握按鈕
                    IconButton(
                      onPressed: widget.word.mastered ? null : widget.onMarkMastered,
                      icon: Icon(
                        widget.word.mastered 
                            ? Icons.check_circle 
                            : Icons.check_circle_outline,
                      ),
                      color: widget.word.mastered ? Colors.green : Colors.grey,
                      iconSize: 32,
                      tooltip: widget.word.mastered ? '已掌握' : '標記為已掌握',
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                const Text(
                  '點擊卡片查看詳情',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildBackCard() {
    return Column(
      children: [
        // 卡片頂部
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              const Text(
                '單字詳情',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.volume_up,
                  color: Colors.white,
                ),
                onPressed: widget.onPlayAudio,
                tooltip: '播放發音',
              ),
            ],
          ),
        ),
        
        // 單字詳情
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 單字和翻譯
                  Center(
                    child: Column(
                      children: [
                        Text(
                          widget.word.word,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.word.translation,
                          style: const TextStyle(
                            fontSize: 22,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // 定義
                  if (widget.word.definition != null) ...[
                    const Text(
                      '定義:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.word.definition!,
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // 例句
                  if (widget.word.example != null) ...[
                    const Text(
                      '例句:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        widget.word.example!,
                        style: const TextStyle(
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // 底部提示
                  const Center(
                    child: Text(
                      '點擊卡片返回',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}