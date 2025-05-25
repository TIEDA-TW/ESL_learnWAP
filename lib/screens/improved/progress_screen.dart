import 'package:flutter/material.dart';
import '../../models/book_model.dart';
import '../../services/user_service_improved.dart';

class ProgressScreen extends StatefulWidget {
  final List<Book> books;
  
  const ProgressScreen({
    Key? key,
    required this.books,
  }) : super(key: key);

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late ImprovedUserService _userService;
  Map<String, int> _progress = {};
  Map<String, int> _masteredWords = {};
  Map<String, int> _gameScores = {};
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _userService = ImprovedUserService();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final progress = await _userService.getRecentProgress();
      
      // 獲取掌握的單字數量
      final masteredWords = await _userService.getMasteredWordCounts();
      
      // 獲取遊戲得分
      final gameScores = await _userService.getGameScores();
      
      setState(() {
        _progress = progress;
        _masteredWords = masteredWords;
        _gameScores = gameScores;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('載入數據失敗: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('學習進度'),
      ),
      body: ListView(
        children: [
          _buildSummaryCard(),
          ...widget.books.map((book) {
            final progress = _progress[book.id] ?? 0;
            final masteredCount = _masteredWords[book.id] ?? 0;
            final gameScore = _gameScores[book.id] ?? 0;
            
            return Card(
              margin: const EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    const SizedBox(height: 8),
                    Text('閱讀進度: $progress%'),
                    const SizedBox(height: 4),
                    Text('已掌握單詞: $masteredCount'),
                    const SizedBox(height: 4),
                    Text('遊戲最高分: $gameScore'),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
  
  Widget _buildSummaryCard() {
    final totalProgress = _progress.values.fold<int>(0, (sum, value) => sum + value);
    final averageProgress = _progress.isEmpty ? 0 : totalProgress ~/ _progress.length;
    
    final totalMasteredWords = _masteredWords.values.fold<int>(0, (sum, value) => sum + value);
    final totalGameScore = _gameScores.values.fold<int>(0, (sum, value) => sum + value);
    
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '總體學習進度',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text('平均閱讀進度: $averageProgress%'),
            const SizedBox(height: 8),
            Text('總掌握單詞數: $totalMasteredWords'),
            const SizedBox(height: 8),
            Text('總遊戲得分: $totalGameScore'),
          ],
        ),
      ),
    );
  }
}