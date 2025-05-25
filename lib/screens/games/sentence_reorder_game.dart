import 'package:flutter/material.dart';
import '../../models/vocabulary_model.dart';
import '../../services/improved/tts_service.dart';

class SentenceReorderGame extends StatefulWidget {
  final String bookId;
  const SentenceReorderGame({Key? key, required this.bookId}) : super(key: key);
  @override
  State<SentenceReorderGame> createState() => _SentenceReorderGameState();
}

class _SentenceReorderGameState extends State<SentenceReorderGame> {
  late final VocabularyService _vocabService;
  late final TtsService _ttsService;
  List<VocabularyItem> _sentences = [];
  int _currentIndex = 0;
  List<String> _shuffled = [];
  String? _feedback;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _vocabService = VocabularyService();
    _ttsService = TtsService();
    _loadSentences();
  }

  Future<void> _loadSentences() async {
    setState(() { _isLoading = true; });
    final all = await _vocabService.getVocabularyForBook(widget.bookId);
    setState(() {
      _sentences = all.where((v) => v.category.toLowerCase() == 'sentence').toList();
      _sentences.shuffle();
      _isLoading = false;
      _setupShuffled();
    });
  }

  void _setupShuffled() {
    if (_sentences.isNotEmpty) {
      final words = _sentences[_currentIndex].word.split(' ');
      _shuffled = List<String>.from(words)..shuffle();
    }
  }

  Future<void> _playAudio() async {
    if (_sentences.isNotEmpty) {
      await _ttsService.stop();
      await _ttsService.speak(_sentences[_currentIndex].word);
    }
  }

  void _submit() {
    final answer = _sentences[_currentIndex].word.trim();
    final user = _shuffled.join(' ').trim();
    setState(() {
      _feedback = (answer == user) ? '正確!' : '再試一次';
    });
  }

  void _next() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _sentences.length;
      _feedback = null;
      _setupShuffled();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_sentences.isEmpty) return const Center(child: Text('無句子題目'));
    final sentence = _sentences[_currentIndex];
    final imagePath = 'assets/images/${sentence.word.replaceAll(' ', '_')}.jpg';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('請還原正確句子', style: TextStyle(fontSize: 20)),
        const SizedBox(height: 16),
        Image.asset(imagePath, width: 180, height: 120, errorBuilder: (_, __, ___) => Container(width:180, height:120, color:Colors.grey[200], child:Icon(Icons.image_not_supported))),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: Icon(Icons.volume_up),
          label: Text('播放語音'),
          onPressed: _playAudio,
        ),
        Wrap(
          spacing: 8,
          children: _shuffled.map((w) => Draggable<String>(
            data: w,
            feedback: Material(child: Chip(label: Text(w))),
            child: DragTarget<String>(
              onAccept: (data) {
                final from = _shuffled.indexOf(data);
                final to = _shuffled.indexOf(w);
                setState(() {
                  final t = _shuffled[from];
                  _shuffled[from] = _shuffled[to];
                  _shuffled[to] = t;
                });
              },
              builder: (context, candidate, rejected) => Chip(label: Text(w)),
            ),
          )).toList(),
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
