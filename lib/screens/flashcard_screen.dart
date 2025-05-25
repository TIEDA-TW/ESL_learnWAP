import 'package:flutter/material.dart';
import '../services/flashcard_service.dart';
import '../services/improved/tts_service.dart';
import '../models/book_model.dart';

class FlashcardScreen extends StatefulWidget {
  final String bookPath;

  FlashcardScreen({required this.bookPath});

  @override
  _FlashcardScreenState createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  late Future<List<TextRegion>> _wordsFuture;
  TextRegion? _currentWord;
  bool _showTranslation = false;
  final FlashcardService _flashcardService = FlashcardService();
  
  // 語速設定
  static const List<double> _speechRates = [0.5, 0.7, 1.0];
  static const List<String> _speechRateLabels = ['慢', '正常', '快'];
  int _speechRateIndex = 1; // 預設為 0.7 (正常)
  double get _speechRate => _speechRates[_speechRateIndex];

  @override
  void initState() {
    super.initState();
    _wordsFuture = _flashcardService.loadWordsFromBook(widget.bookPath);
  }

  void _showNextWord(List<TextRegion> words) {
    if (words.isEmpty) return;
    setState(() {
      _currentWord = words.removeAt(0);
      _showTranslation = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flashcard'),
        actions: [
          PopupMenuButton<int>(
            icon: Icon(Icons.speed),
            onSelected: (index) {
              setState(() {
                _speechRateIndex = index;
              });
            },
            itemBuilder: (context) => List.generate(_speechRates.length, (i) => 
              PopupMenuItem(
                value: i,
                child: Row(
                  children: [
                    Text(_speechRateLabels[i]),
                    if (_speechRateIndex == i) ...[
                      SizedBox(width: 8),
                      Icon(Icons.check, size: 16),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<TextRegion>>(
        future: _wordsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final words = snapshot.data!;
            if (_currentWord == null) {
              _showNextWord(words);
            }
            return _buildFlashcard(words);
          } else if (snapshot.hasError) {
            return Center(child: Text('Failed to load words'));
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Widget _buildFlashcard(List<TextRegion> words) {
    if (_currentWord == null) {
      return Center(child: Text('No more words'));
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _currentWord!.text,
          style: TextStyle(fontSize: 64),
        ),
        SizedBox(height: 16),
        if (_showTranslation)
          Text(
            _currentWord!.translation ?? 'No translation',
            style: TextStyle(fontSize: 32),
          ),
        SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: Text('Show Translation'),
              onPressed: () {
                setState(() {
                  _showTranslation = true;
                });
              },
            ),
            SizedBox(width: 16),
            ElevatedButton(
              child: Text('Next Word'),
              onPressed: () {
                _showNextWord(words);
              },
            ),
            SizedBox(width: 16),
            ElevatedButton(
              child: Text('Listen'),
              onPressed: () {
                TtsService().speak(_currentWord!.text, rate: _speechRate);
              },
            ),
          ],
        ),
      ],
    );
  }
}
