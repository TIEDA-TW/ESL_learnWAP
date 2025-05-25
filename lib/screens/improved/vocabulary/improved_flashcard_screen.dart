import 'package:flutter/material.dart';
import '../../../models/book_model.dart';
import '../../../services/flashcard_service.dart';
import './flashcard_item.dart';

class ImprovedFlashcardScreen extends StatefulWidget {
  final String bookId;

  ImprovedFlashcardScreen({required this.bookId});

  @override
  _ImprovedFlashcardScreenState createState() => _ImprovedFlashcardScreenState();
}

class _ImprovedFlashcardScreenState extends State<ImprovedFlashcardScreen> {
  late Future<List<TextRegion>> _wordsFuture;
  final FlashcardService _flashcardService = FlashcardService();

  @override
  void initState() {
    super.initState();
    // 根據書籍ID獲取對應的JSON文件路徑
    String bookDataPath = 'assets/Book_data/${widget.bookId}_book_data.json';
    // 從JSON文件中加載單詞數據
    _wordsFuture = _flashcardService.loadWordsFromBook(bookDataPath);
  }

  @override
  int _currentIndex = 0;
  bool _showTranslationFirst = false; // User preference for new cards

  void _nextCard(int totalWords) {
    if (_currentIndex < totalWords - 1) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  void _previousCard() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<List<TextRegion>>(
          future: _wordsFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text('Flashcards (${_currentIndex + 1} / ${snapshot.data!.length})');
            }
            return Text('Flashcards (${_currentIndex + 1} / ...)'); // 在加載完成前顯示佔位符
          },
        ),
        actions: [
          IconButton(
            icon: Icon(_showTranslationFirst ? Icons.visibility_off : Icons.visibility),
            tooltip: _showTranslationFirst ? 'Show word first' : 'Show translation first',
            onPressed: () {
              setState(() {
                _showTranslationFirst = !_showTranslationFirst;
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<TextRegion>>(
        future: _wordsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Failed to load words: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No words found for this book.'));
          } else {
            final words = snapshot.data!;
            // 更新 AppBar 標題的正確方式，使用 setState
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) { // Check if the widget is still in the tree
                 setState(() {
                   // AppBar 標題將在下次構建時顯示更新後的值
                   // 這裡我們不需要做任何事情，因為我們可以直接在 AppBar 的 title 中使用 words.length
                 });
              }
            });

            final currentWord = words[_currentIndex];

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: FlashcardItem(
                      textRegion: currentWord,
                      showTranslationFirst: _showTranslationFirst,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SpeakButton(text: currentWord.text), // TTS button for the current word
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Previous'),
                        onPressed: _currentIndex > 0 ? _previousCard : null,
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(120, 48),
                        ),
                      ),
                      Text(
                        '${_currentIndex + 1}/${words.length}',
                        style: theme.textTheme.titleMedium,
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Next'),
                        onPressed: _currentIndex < words.length - 1 ? () => _nextCard(words.length) : null,
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(120, 48),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
