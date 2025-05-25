import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../../utils/web_speech_helper.dart';
import '../../models/vocabulary_model.dart';
import '../../services/improved/tts_service.dart';

class WordMatchGame extends StatefulWidget {
  final String bookId;
  final String difficulty;

  WordMatchGame({
    Key? key,
    required this.bookId,
    this.difficulty = 'Easy',
  }) : super(key: key);

  @override
  State<WordMatchGame> createState() => _WordMatchGameState();
}

class _WordMatchGameState extends State<WordMatchGame> with SingleTickerProviderStateMixin {
  static const List<double> _speechRates = [0.5, 0.7, 1.0];
  static const List<String> _speechRateLabels = ['慢', '正常', '快'];
  int _speechRateIndex = 1; // 預設 0.7

  double get _speechRate => _speechRates[_speechRateIndex];

  // Widget: 語速切換按鈕
  Widget _buildSpeechRateButton() {
    return IconButton(
      icon: Icon(Icons.speed),
      tooltip: '語音速度：' + _speechRateLabels[_speechRateIndex],
      onPressed: () {
        setState(() {
          _speechRateIndex = (_speechRateIndex + 1) % _speechRates.length;
        });
      },
    );
  }

  late final VocabularyService _vocabService;
  // Game state
  List<VocabularyItem> _allVocabulary = [];
  List<VocabularyItem> _gameVocabulary = [];
  List<VocabularyItem> _currentRoundItems = [];
  String? _selectedWord;
  String? _selectedImage;
  int _currentRound = 1;
  int _totalRounds = 5;
  int _score = 0;
  int _streak = 0;
  bool _isLoading = true;
  bool _gameOver = false;
  bool _showFeedback = false;
  bool _isCorrectMatch = false;

  // Animation controller for card flipping and feedback
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _vocabService = VocabularyService();

    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Load game data
    _loadGameData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Load vocabulary data for the game
  Future<void> _loadGameData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load vocabulary from selected book
      _allVocabulary = await _vocabService.getVocabularyForBook(widget.bookId);

      // 僅取 Category = 'Word' 的資料
      _gameVocabulary = _allVocabulary
          .where((vocab) => vocab.category.toLowerCase() == 'word')
          .toList();

      // 若不足題數，可補充
      if (_gameVocabulary.length < 10) {
        final additionalWords = _allVocabulary
            .where((vocab) => vocab.category.toLowerCase() != 'word')
            .take(10 - _gameVocabulary.length)
            .toList();
        _gameVocabulary.addAll(additionalWords);
      }

      // Shuffle vocabulary list
      _gameVocabulary.shuffle();

      // Start first round
      _setupRound();
    } catch (e) {
      print('載入遊戲數據失敗: $e');
      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('遊戲載入失敗'),
          content: Text('無法載入單字數據: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('返回'),
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Setup a new game round with word-image pairs
  void _setupRound() {
    // Select 4 random items for this round
    final roundItems = List<VocabularyItem>.from(_gameVocabulary);
    roundItems.shuffle();
    _currentRoundItems = roundItems.take(4).toList();

    // Reset selections
    _selectedWord = null;
    _selectedImage = null;
    _showFeedback = false;

    setState(() {});
  }

  // Handle word selection
  void _selectWord(String word) {
    setState(() {
      _selectedWord = word;
      _checkMatch();
    });

    // Play word audio
    final selectedVocab = _currentRoundItems.firstWhere((item) => item.word == word);
    TtsService().speak(selectedVocab.word, rate: _speechRate);
  }

  // Handle image selection
  void _selectImage(String word) {
    setState(() {
      _selectedImage = word;
      _checkMatch();
    });
  }

  // Check if selected word and image match
  void _checkMatch() {
    if (_selectedWord != null && _selectedImage != null) {
      final isCorrect = _selectedWord == _selectedImage;

      setState(() {
        _showFeedback = true;
        _isCorrectMatch = isCorrect;
      });

      // Play appropriate sound effect
      if (isCorrect) {
        TtsService().speak('正確', rate: _speechRate);
        _score += 10 + (_streak * 2); // Bonus points for streaks
        _streak++;
      } else {
        TtsService().speak('錯誤', rate: _speechRate);
        _streak = 0;
      }

      // Animate feedback
      _animationController.forward().then((_) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (!mounted) return;
          setState(() {
            _showFeedback = false;
          });
          if (isCorrect) {
            if (_currentRound < _totalRounds) {
              setState(() {
                _currentRound++;
              });
              _setupRound();
            } else {
              setState(() {
                _gameOver = true;
              });
            }
          } else {
            // For wrong answers, just reset the selections
            setState(() {
              _selectedWord = null;
              _selectedImage = null;
            });
          }
        });
      });
    }
  }

  // Start a new game
  void _restartGame() {
    setState(() {
      _currentRound = 1;
      _score = 0;
      _streak = 0;
      _gameOver = false;
    });
    _setupRound();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('單字配對遊戲'),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_gameOver) {
      return _buildGameOverScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('單字配對遊戲'),
        centerTitle: true,
        actions: [
          _buildSpeechRateButton(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Text(
                '分數: $_score',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress and score area
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Round counter
                Text(
                  '回合: $_currentRound/$_totalRounds',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // Streak counter
                Row(
                  children: [
                    Icon(
                      Icons.bolt,
                      color: _streak > 0 ? Colors.amber : Colors.grey,
                    ),
                    Text(
                      '連續: $_streak',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _streak > 0 ? Colors.amber.shade800 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Feedback area (shows temporarily after match attempt)
          if (_showFeedback)
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.all(16.0),
                  color: _isCorrectMatch
                      ? Colors.green.withOpacity(_animation.value * 0.3)
                      : Colors.red.withOpacity(_animation.value * 0.3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isCorrectMatch ? Icons.check_circle : Icons.cancel,
                        color: _isCorrectMatch ? Colors.green : Colors.red,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isCorrectMatch ? '太棒了！正確匹配！' : '再試一次！',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _isCorrectMatch ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          // Game instruction
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '將單字與正確的圖片配對',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Words column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          '單字',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _currentRoundItems.length,
                            itemBuilder: (context, index) {
                              final word = _currentRoundItems[index].word;

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: _buildWordCard(word),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Images column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          '圖片',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _currentRoundItems.length,
                            itemBuilder: (context, index) {
                              // Shuffle the order of images
                              final shuffledIndex = (index + 2) % _currentRoundItems.length;
                              final word = _currentRoundItems[shuffledIndex].word;

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: _buildImageCard(word),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordCard(String word) {
    final isSelected = word == _selectedWord;

    return Card(
      elevation: isSelected ? 8 : 2,
      color: isSelected ? Colors.blue.shade100 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _selectWord(word),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  word,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Icon(
                Icons.volume_up,
                color: Colors.blue.shade700,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageCard(String word) {
    final isSelected = word == _selectedImage;
    final correspondingVocab = _currentRoundItems.firstWhere((item) => item.word == word);
    final imageFile = correspondingVocab.imageFile;

    return Card(
      elevation: isSelected ? 8 : 2,
      color: isSelected ? Colors.green.shade100 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.green : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _selectImage(word),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: AspectRatio(
            aspectRatio: 1.5,
            child: imageFile != null
                ? Image.asset(
                    'assets/images/$imageFile',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback illustration when image is not available
                      return Center(
                        child: Icon(
                          _getIconForWord(word),
                          size: 50,
                          color: Colors.blue.shade700,
                        ),
                      );
                    },
                  )
                : Center(
                    child: Icon(
                      _getIconForWord(word),
                      size: 50,
                      color: Colors.blue.shade700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // Get appropriate icon for word when image is not available
  IconData _getIconForWord(String word) {
    final lowerWord = word.toLowerCase();

    if (lowerWord.contains('apple')) return Icons.apple;
    if (lowerWord.contains('banana')) return Icons.food_bank;
    if (lowerWord.contains('cat')) return Icons.pets;
    if (lowerWord.contains('dog')) return Icons.pets;
    if (lowerWord.contains('elephant')) return Icons.pets;
    if (lowerWord.contains('fish')) return Icons.set_meal;
    if (lowerWord.contains('book')) return Icons.book;
    if (lowerWord.contains('pencil')) return Icons.edit;
    if (lowerWord.contains('happy')) return Icons.sentiment_very_satisfied;
    if (lowerWord.contains('sad')) return Icons.sentiment_very_dissatisfied;
    if (lowerWord.contains('car')) return Icons.directions_car;
    if (lowerWord.contains('house')) return Icons.home;
    if (lowerWord.contains('school')) return Icons.school;
    if (lowerWord.contains('teacher')) return Icons.people;

    return Icons.image;
  }

  Widget _buildGameOverScreen() {
    // Calculate stars based on score
    int stars = 0;
    if (_score > 70) stars = 3;
    else if (_score > 40) stars = 2;
    else if (_score > 20) stars = 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('遊戲結束'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              '恭喜完成遊戲!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '你的分數: $_score 分',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),

            // Star display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return Icon(
                  index < stars ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 50,
                );
              }),
            ),

            const SizedBox(height: 32),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _restartGame,
                  icon: const Icon(Icons.refresh),
                  label: const Text('再玩一次'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('返回主頁'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}