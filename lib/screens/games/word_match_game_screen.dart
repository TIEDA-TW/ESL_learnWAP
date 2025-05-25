// word_match_game_screen.dart
// 原 word_match_game.dart 內容移至此檔案

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert'; 
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/vocabulary_model.dart';
import '../../widgets/speech_rate_button.dart';

class WordMatchGameScreen extends StatefulWidget {
  final String? bookId;
  final String difficulty;

  const WordMatchGameScreen({
    Key? key,
    this.bookId,
    this.difficulty = 'Easy',
  }) : super(key: key);

  @override
  State<WordMatchGameScreen> createState() => _WordMatchGameScreenState();
}

class _WordMatchGameScreenState extends State<WordMatchGameScreen> {
  String? _selectedBookId;
  List<String> _allBookIds = [];
  List<VocabularyItem> _vocabList = [];
  List<VocabularyItem> _leftList = [];
  List<VocabularyItem> _rightList = [];
  Map<String, String> _matchResult = {};
  bool _isLoading = false;
  String? _error;
  FlutterTts _tts = FlutterTts();
  int _score = 0;
  int _streak = 0;
  bool _showReward = false;
  int? _selectedLeftIdx;
  int? _selectedRightIdx;
  double _speechRate = 0.7;
  static const List<double> _speechRates = [0.5, 0.7, 1.0];
  static const List<String> _speechRateLabels = ['慢', '正常', '快'];
  int _speechRateIndex = 1;

  @override
  void initState() {
    super.initState();
    _initTTS();
    _loadBookIds();
    _selectedBookId = widget.bookId;
    if (_selectedBookId != null) {
      _loadVocabulary(_selectedBookId!);
    }
  }

  Future<void> _initTTS() async {
    // 預先初始化 TTS 避免首播聲音異常
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(_speechRate);
    await _tts.speak(" "); // 播放空白字元
    await _tts.stop();
  }

  Future<void> _loadBookIds() async {
    final manifestContent = await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = manifestContent.isNotEmpty ? Map<String, dynamic>.from(json.decode(manifestContent)) : {};
    final ids = <String>{};
    manifestMap.keys.forEach((String key) {
      final match = RegExp(r'assets/Book_data/(.+)_book_data.json').firstMatch(key);
      if (match != null) {
        ids.add(match.group(1)!);
      }
    });
    setState(() { _allBookIds = ids.toList(); });
  }

  Future<void> _loadVocabulary(String bookId) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _showReward = false;
      _selectedLeftIdx = null;
      _selectedRightIdx = null;
    });
    try {
      final items = await VocabularyService().getVocabularyForBook(bookId);
      items.shuffle();
      setState(() {
        _vocabList = items;
        _leftList = List.from(items);
        _rightList = List.from(items)..shuffle();
        _matchResult.clear();
        _isLoading = false;
        _score = 0;
        _streak = 0;
      });
    } catch (e) {
      setState(() {
        _error = '載入單字失敗: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _playTTS(String text) async {
    try {
      await _tts.stop(); // 先停止前一個語音
      // 依平台調整語音語言
      if (text.trim().contains(RegExp(r'^[A-Za-z]'))) {
        await _tts.setLanguage("en-US");
      } else {
        await _tts.setLanguage("zh-TW");
      }
      await _tts.setSpeechRate(_speechRate);
      await _tts.speak(text);
    } catch (e) {
      print("TTS error: $e");
    }
  }

  void _onTapLeft(int idx) {
    setState(() {
      _selectedLeftIdx = idx;
    });
    _playTTS(_leftList[idx].word); // 點擊左側播英文
    if (_selectedRightIdx != null) {
      _checkMatch(idx, _selectedRightIdx!);
    }
  }

  void _onTapRight(int idx) {
    setState(() {
      _selectedRightIdx = idx;
    });
    _playTTS(_rightList[idx].translation); // 點擊右側播中文
    if (_selectedLeftIdx != null) {
      _checkMatch(_selectedLeftIdx!, idx);
    }
  }

  void _checkMatch(int leftIdx, int rightIdx) {
    final left = _leftList[leftIdx];
    final right = _rightList[rightIdx];
    setState(() {
      if (left.word == right.word) {
        _matchResult[left.word] = 'correct';
        _score++;
        _streak++;
        if (_streak % 5 == 0) _showReward = true;
      } else {
        _matchResult[left.word] = 'wrong';
        _streak = 0;
      }
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        if (left.word == right.word) {
          _leftList.removeAt(leftIdx);
          _rightList.removeAt(rightIdx);
        }
        _matchResult.remove(left.word);
        _selectedLeftIdx = null;
        _selectedRightIdx = null;
        _showReward = false;
      });
    });
  }

  Widget _buildCard({
    required Widget child,
    required bool selected,
    required bool correct,
    required bool wrong,
    required VoidCallback onTap,
    Color? color,
    double elevation = 8,
  }) {
    Color bgColor = color ?? Colors.white;
    if (correct) bgColor = Colors.green[200]!;
    if (wrong) bgColor = Colors.red[200]!;
    if (selected) bgColor = Colors.blue[100]!;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
      child: Material(
        elevation: elevation,
        borderRadius: BorderRadius.circular(28),
        color: bgColor,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        titleSpacing: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              '單字配對遊戲',
              style: GoogleFonts.notoSans(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 24),
            const Text('教材：', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: _selectedBookId,
              hint: const Text('請選擇'),
              underline: SizedBox(),
              style: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
              dropdownColor: Colors.grey[900],
              items: _allBookIds.map((id) => DropdownMenuItem(
                value: id,
                child: Text(id, style: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.w600)),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedBookId = value;
                });
                if (value != null) _loadVocabulary(value);
              },
            ),
          ],
        ),
        actions: [
          SpeechRateButton(
            speechRates: _speechRates,
            speechRateLabels: _speechRateLabels,
            currentIndex: _speechRateIndex,
            onRateChanged: (index) {
              setState(() {
                _speechRateIndex = index;
                _speechRate = _speechRates[index];
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('得分：$_score', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('連續正確：$_streak', style: const TextStyle(fontSize: 16, color: Colors.white70)),
              ],
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(child: CircularProgressIndicator()),
            if (_error != null)
              Center(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 18))),
            if (!_isLoading && _error == null && _selectedBookId != null)
              Expanded(
                child: _leftList.isEmpty
                  ? Center(
                      child: Text('恭喜完成所有配對！', style: GoogleFonts.notoSans(fontSize: 22, fontWeight: FontWeight.bold)),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: _leftList.length,
                            itemBuilder: (context, idx) {
                              final item = _leftList[idx];
                              return _buildCard(
                                child: ListTile(
                                  title: Row(
                                    children: [
                                      Text(item.word, style: GoogleFonts.notoSans(fontSize: 24, fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.volume_up_rounded, color: Colors.blue),
                                        onPressed: () => _playTTS(item.word),
                                      ),
                                    ],
                                  ),
                                ),
                                selected: _selectedLeftIdx == idx,
                                correct: _matchResult[item.word] == 'correct',
                                wrong: _matchResult[item.word] == 'wrong',
                                onTap: () => _onTapLeft(idx),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _rightList.length,
                            itemBuilder: (context, idx) {
                              final item = _rightList[idx];
                              return _buildCard(
                                child: Center(
                                  child: Text(item.translation, style: GoogleFonts.notoSans(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal[900])),
                                ),
                                selected: _selectedRightIdx == idx,
                                correct: false,
                                wrong: false,
                                onTap: () => _onTapRight(idx),
                                color: Colors.white,
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
    );
  }
}
