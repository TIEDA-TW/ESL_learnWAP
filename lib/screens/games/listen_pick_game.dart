import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import '../../models/vocabulary_model.dart';
import '../../services/improved/tts_service.dart';
import 'package:flutter/foundation.dart';
import '../../utils/web_speech_helper.dart';

class ListenPickGame extends StatefulWidget {
  final String bookId;
  final String difficulty;

  const ListenPickGame({
    Key? key, 
    required this.bookId,
    this.difficulty = 'Easy',
  }) : super(key: key);

  @override
  State<ListenPickGame> createState() => _ListenPickGameState();
}

class _ListenPickGameState extends State<ListenPickGame> with TickerProviderStateMixin {
  // 語音語速等級
  static const List<double> _speechRates = [0.5, 0.7, 1.0];
  static const List<String> _speechRateLabels = ['慢', '正常', '快'];
  int _speechRateIndex = 1; // 預設 0.7

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

  double get _speechRate => _speechRates[_speechRateIndex];

  late final VocabularyService _vocabService;
  late final TtsService _ttsService;
  
  // Game state
  List<VocabularyItem> _allVocabulary = [];
  List<VocabularyItem> _gameVocabulary = [];
  List<String> _options = [];
  String _correctAnswer = '';
  VocabularyItem? _currentWord;
  int _currentRound = 1;
  int _totalRounds = 10;
  int _score = 0;
  int _streak = 0;
  bool _isLoading = true;
  bool _gameOver = false;
  bool _showFeedback = false;
  bool _isCorrectChoice = false;
  String? _selectedOption;
  bool _canSelectOption = true;
  
  // Animation controllers
  late AnimationController _feedbackAnimationController;
  late Animation<double> _feedbackAnimation;
  late AnimationController _playButtonAnimationController;
  late Animation<double> _playButtonAnimation;
  late AnimationController _optionAnimationController;
  late Animation<double> _optionAnimation;
  
  @override
  void initState() {
    super.initState();
    _initTTS();
    _vocabService = VocabularyService();
    _ttsService = TtsService();
    
    // Setup animations
    _feedbackAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _feedbackAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _feedbackAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _playButtonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _playButtonAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _playButtonAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _optionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _optionAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _optionAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Load game data
    _loadGameData();
  }
  
  Future<void> _initTTS() async {
    // 預先初始化 TTS 避免首播聲音異常
    await _ttsService.speak(" ");
    await _ttsService.stop();
  }
  
  @override
  void dispose() {
    _feedbackAnimationController.dispose();
    _playButtonAnimationController.dispose();
    _optionAnimationController.dispose();
    super.dispose();
  }
  
  // Load vocabulary data for the game
  Future<void> _loadGameData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      _allVocabulary = await _vocabService.getVocabularyForBook(widget.bookId);
      // 僅取 Category = 'Word' 的資料
      _gameVocabulary = _allVocabulary.where((vocab) => vocab.category.toLowerCase() == 'word').toList();
      _gameVocabulary.shuffle();
      _currentRound = 1;
      _score = 0;
      _streak = 0;
      _gameOver = false;
      _showFeedback = false;
      _setupRound();
    } catch (e) {
      print('載入遊戲數據失敗: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Setup a new game round with a target word and options
  void _setupRound() {
    if (_gameVocabulary.isEmpty) {
      setState(() {
        _gameOver = true;
      });
      return;
    }
    
    // Reset state for new round
    _selectedOption = null;
    _canSelectOption = true;
    _showFeedback = false;
    
    // Select a random word for this round
    final random = Random();
    final wordIndex = random.nextInt(_gameVocabulary.length);
    _currentWord = _gameVocabulary[wordIndex];
    _correctAnswer = _currentWord!.word;
    
    // Remove the used word from the pool
    _gameVocabulary.removeAt(wordIndex);
    
    // Generate wrong options
    _options = [_correctAnswer];
    
    // Add 3 incorrect options
    final shuffledVocab = List<VocabularyItem>.from(_allVocabulary);
    shuffledVocab.shuffle();
    
    for (var word in shuffledVocab) {
      if (word.word != _correctAnswer && !_options.contains(word.word)) {
        _options.add(word.word);
        if (_options.length >= 4) break;
      }
    }
    
    // Ensure we have 4 options (in case we don't have enough words)
    while (_options.length < 4) {
      _options.add('Option ${_options.length + 1}');
    }
    
    // Shuffle options so correct answer isn't always first
    _options.shuffle();
    
    setState(() {});
    
    // Auto-play the audio after a brief delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _currentWord != null) {
        _playWordAudio(_currentWord!);
      }
    });
  }
  
  // Play the audio for the current word
  Future<void> _playWordAudio(VocabularyItem vocab) async {
    _playButtonAnimationController.forward().then((_) {
      _playButtonAnimationController.reverse();
    });
    try {
      await _ttsService.stop();
      await Future.delayed(const Duration(milliseconds: 150));
      await _ttsService.speak(vocab.word, rate: _speechRate);
    } catch (e) {
      print('TTS 播放失敗: $e');
      // 可加 UI 提示
    }
  }
  
  // Handle option selection
  Future<void> _selectOption(String option) async {
    if (!_canSelectOption) return;
    
    setState(() {
      _selectedOption = option;
      _canSelectOption = false;
    });
    
    // Animate the option press
    _optionAnimationController.forward().then((_) {
      _optionAnimationController.reverse();
    });
    
    // Check if correct
    final isCorrect = option == _correctAnswer;
    
    setState(() {
      _showFeedback = true;
      _isCorrectChoice = isCorrect;
    });
    
    // Play appropriate sound effect and update score
    if (isCorrect) {
      await _ttsService.stop();
      await _ttsService.speak('正確', rate: _speechRate, lang: 'zh-TW');
      _score += 10 + (_streak * 2); // Bonus points for streaks
      _streak++;
    } else {
      await _ttsService.stop();
      await _ttsService.speak('錯誤', rate: _speechRate, lang: 'zh-TW');
      _streak = 0;
    }
    
    // Animate feedback
    _feedbackAnimationController.forward();
    
    // Delay before moving to next round or ending game
    await Future.delayed(const Duration(milliseconds: 1500));
    setState(() {
      _showFeedback = false;
    });
    
    // Move to next round if correct, otherwise stay and let user try again
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
      // Re-enable option selection for retry
      setState(() {
        _canSelectOption = true;
        _selectedOption = null;
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
    _loadGameData(); // Reload all data to reset the game
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('聽力選擇遊戲'),
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
        title: const Text('聽力選擇遊戲'),
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
            color: Colors.green.shade50,
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
              animation: _feedbackAnimation,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.all(16.0),
                  color: _isCorrectChoice
                      ? Colors.green.withOpacity(_feedbackAnimation.value * 0.3)
                      : Colors.red.withOpacity(_feedbackAnimation.value * 0.3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isCorrectChoice ? Icons.check_circle : Icons.cancel,
                        color: _isCorrectChoice ? Colors.green : Colors.red,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isCorrectChoice ? '太棒了！正確答案！' : '再試一次！',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _isCorrectChoice ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          
          // Audio play section
          Expanded(
            flex: 2,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '點擊播放並選擇你聽到的單字',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  AnimatedBuilder(
                    animation: _playButtonAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _playButtonAnimation.value,
                        child: ElevatedButton(
                          onPressed: () => _playWordAudio(_currentWord!),
                          style: ElevatedButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(24),
                            backgroundColor: Colors.green,
                          ),
                          child: const Icon(
                            Icons.volume_up,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                  if (_currentWord != null && _isCorrectChoice) ...[
                    const SizedBox(height: 16),
                    Text(
                      _currentWord!.translation,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Word options
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Scrollbar(
                thumbVisibility: true,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.5,
                  ),
                  itemCount: _options.length,
                  itemBuilder: (context, index) {
                    final option = _options[index];
                    final isSelected = option == _selectedOption;
                    final isCorrect = option == _correctAnswer && isSelected;
                    final isWrong = isSelected && option != _correctAnswer;
                    
                    Color cardColor = Colors.white;
                    Color borderColor = Colors.grey.shade300;
                    
                    if (_showFeedback) {
                      if (isCorrect) {
                        cardColor = Colors.green.shade100;
                        borderColor = Colors.green;
                      } else if (isWrong) {
                        cardColor = Colors.red.shade100;
                        borderColor = Colors.red;
                      }
                    } else if (isSelected) {
                      cardColor = Colors.blue.shade100;
                      borderColor = Colors.blue;
                    }
                    
                    return AnimatedBuilder(
                      animation: _optionAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: isSelected ? _optionAnimation.value : 1.0,
                          child: Card(
                            elevation: isSelected ? 8 : 2,
                            color: cardColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: borderColor,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: InkWell(
                              onTap: _canSelectOption ? () => _selectOption(option) : null,
                              borderRadius: BorderRadius.circular(12),
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    option,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
          
          // Translation hint (only shown if there's feedback and it's correct)
          if (_currentWord != null && _showFeedback && _isCorrectChoice)
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '${_currentWord!.word} = ${_currentWord!.translation}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildGameOverScreen() {
    // Calculate stars based on score
    int stars = 0;
    if (_score > 130) stars = 3;
    else if (_score > 80) stars = 2;
    else if (_score > 40) stars = 1;
    
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
                color: Colors.green,
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