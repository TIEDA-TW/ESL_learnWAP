import 'package:flutter/material.dart';
import '../../models/vocabulary_model.dart';
import '../../services/improved/tts_service.dart';

class SpellingGame extends StatefulWidget {
  final String bookId;
  const SpellingGame({Key? key, required this.bookId}) : super(key: key);
  @override
  State<SpellingGame> createState() => _SpellingGameState();
}

class _SpellingGameState extends State<SpellingGame> {
  late final VocabularyService _vocabService;
  late final TtsService _ttsService;
  List<VocabularyItem> _words = [];
  int _currentIndex = 0;
  String _input = '';
  String? _feedback;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _vocabService = VocabularyService();
    _ttsService = TtsService();
    _loadWords();
  }

  Future<void> _loadWords() async {
    setState(() { _isLoading = true; });
    final all = await _vocabService.getVocabularyForBook(widget.bookId);
    setState(() {
      _words = all.where((v) => v.category.toLowerCase() == 'word').toList();
      _words.shuffle();
      _isLoading = false;
    });
  }

  Future<void> _playAudio() async {
    if (_words.isNotEmpty) {
      await _ttsService.stop();
      await _ttsService.speak(_words[_currentIndex].word);
    }
  }

  void _submit() {
    final answer = _words[_currentIndex].word.trim().toLowerCase();
    if (_input.trim().toLowerCase() == answer) {
      setState(() { _feedback = '正確!'; });
    } else {
      setState(() { _feedback = '再試一次'; });
    }
  }

  void _next() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _words.length;
      _input = '';
      _feedback = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_words.isEmpty) return const Center(child: Text('無單字題目'));
    final word = _words[_currentIndex];
    final imagePath = 'assets/images/${word.word}.jpg';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('請拼出單字', style: TextStyle(fontSize: 20)),
        const SizedBox(height: 16),
        Image.asset(imagePath, width: 120, height: 120, errorBuilder: (_, __, ___) => Container(width:120, height:120, color:Colors.grey[200], child:Icon(Icons.image_not_supported))),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: Icon(Icons.volume_up),
          label: Text('播放語音'),
          onPressed: _playAudio,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
          child: TextField(
            onChanged: (v) => setState(() => _input = v),
            decoration: InputDecoration(labelText: '輸入單字'),
          ),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text('送出'),
        ),
        if (_feedback != null) ...[
          Text(_feedback!, style: TextStyle(fontSize: 18, color: _feedback == '正確!' ? Colors.green : Colors.red)),
          if (_feedback == '正確!')
            ElevatedButton(onPressed: _next, child: Text('下一題')),
        ]
      ],
    );
  }
}
