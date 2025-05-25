import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:english_learning_app/utils/web_speech_helper.dart';
import 'package:english_learning_app/services/improved/tts_service.dart';
import '../../../models/book_model.dart';
import '../../../services/improved/audio_service_bridge.dart';
import '../../../services/improved/speech_service_bridge.dart';
import '../../../widgets/improved/pronunciation_feedback.dart';
import '../../../widgets/improved/voice_animation.dart';
import '../../../widgets/speech_rate_button.dart';

class PronunciationPracticeScreen extends StatefulWidget {
  final Book book;

  const PronunciationPracticeScreen({
    Key? key,
    required this.book,
  }) : super(key: key);

  @override
  State<PronunciationPracticeScreen> createState() =>
      _PronunciationPracticeScreenState();
}

class _PronunciationPracticeScreenState
    extends State<PronunciationPracticeScreen> with TickerProviderStateMixin {
  late AudioServiceBridge _audioService;
  late SpeechServiceBridge _speechService;
  bool _isLoading = true;

  // 發音項目
  List<Map<String, dynamic>> _pronunciationItems = [];
  int _currentIndex = 0;

  // 錄音相關
  bool _isRecording = false;
  bool _isPlayingOriginal = false;
  String? _lastRecordingPath;

  // 動畫控制器
  late AnimationController _pulseController;

  // 評估結果
  Map<String, dynamic>? _pronunciationResult;

  // 練習模式
  String _practiceMode = 'word'; // 'word' 或 'sentence'

  // TTS語速設定
  static const List<double> _speechRates = [0.5, 0.7, 1.0];
  static const List<String> _speechRateLabels = ['慢', '正常', '快'];
  int _speechRateIndex = 1; // 預設為 0.7 (正常)
  double get _speechRate => _speechRates[_speechRateIndex];

  @override
  void initState() {
    super.initState();
    _audioService = AudioServiceBridge();
    _speechService = SpeechServiceBridge();

    // 初始化動畫控制器
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _loadPronunciationData(widget.book); // Pass the book object

    // 設置音頻播放完成回調
    _audioService.setOnCompleteListener(() {
      if (_isPlayingOriginal) {
        setState(() {
          _isPlayingOriginal = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioService.dispose();
    _speechService.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // Helper function to load and parse book data from a JSON file path
  Future<Map<String, dynamic>> _loadBookJsonData(String dataPath) async {
    // This mimics StorageService().loadAsset behavior for simplicity here
    // In a real app, you'd use a shared service or pass parsed data.
    final jsonString = await DefaultAssetBundle.of(context).loadString(dataPath);
    return json.decode(jsonString);
  }

  Future<void> _loadPronunciationData(Book currentBook) async {
    setState(() {
      _isLoading = true;
      _pronunciationItems = []; // Clear previous items
    });

    try {
      final bookData = await _loadBookJsonData(currentBook.dataPath);
      final List<Map<String, dynamic>> words = [];
      final List<Map<String, dynamic>> sentences = [];

      if (bookData.containsKey('pages') && bookData['pages'] is List) {
        int itemCounter = 0; // To generate unique IDs

        for (var page in bookData['pages']) {
          if (page.containsKey('regions') && page['regions'] is List) {
            for (var region in page['regions']) {
              final String text = region['text'] ?? '';
              final String translation = region['translation'] ?? (region['中文翻譯'] ?? ''); // Handle both possible keys
              final String audioFile = region['audioFile'] ?? (region['English_Audio_File'] ?? '');
              final String category = region['type'] ?? (region['category'] ?? ''); // Handle both possible keys

              if (text.isNotEmpty) {
                itemCounter++;
                final itemMap = {
                  'id': 'item_$itemCounter',
                  'type': category.toLowerCase(), // 'word' or 'sentence'
                  'text': text,
                  'translation': translation,
                  'audioFile': audioFile, // 音檔檔名，統一使用 audioFile 欄位
                };

                if (category.toLowerCase() == 'word') {
                  words.add(itemMap);
                } else if (category.toLowerCase() == 'sentence') {
                  sentences.add(itemMap);
                }
              }
            }
          }
        }
      }

      if (words.isEmpty && sentences.isEmpty) {
        print('No words or sentences found in book data: ${currentBook.dataPath}');
      }
      
      // Deduplicate items by text to avoid too many similar entries for practice
      final uniqueWords = words.fold<Map<String, Map<String, dynamic>>>(
        {}, (map, item) => map..putIfAbsent(item['text'], () => item)).values.toList();
      
      final uniqueSentences = sentences.fold<Map<String, Map<String, dynamic>>>(
        {}, (map, item) => map..putIfAbsent(item['text'], () => item)).values.toList();


      setState(() {
        _pronunciationItems = _practiceMode == 'word' ? uniqueWords : uniqueSentences;
        if (_pronunciationItems.isEmpty) {
          print("No items for practice mode: $_practiceMode after loading from book.");
        }
        _isLoading = false;
        _currentIndex = 0; // Reset index
        _pronunciationResult = null; // Clear previous result
        _lastRecordingPath = null; // Clear last recording
      });

    } catch (e) {
      print('載入發音練習數據失敗 for book ${currentBook.id}: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('載入發音練習數據失敗: $e. Using mock data as fallback.'),
            backgroundColor: Colors.red,
          ),
        );
        // Fallback to mock data if loading fails
        _loadMockData();
      } else {
        // If not mounted, just load mock data without showing snackbar
        _loadMockData();
      }
    }
  }

  void _loadMockData() {
     // Fallback example data if book loading fails
    final mockWords = [
      {'id': 'mw1', 'type': 'word', 'text': 'Hello', 'translation': '你好', 'audioFile': ''},
      {'id': 'mw2', 'type': 'word', 'text': 'World', 'translation': '世界', 'audioFile': ''},
    ];
    final mockSentences = [
      {'id': 'ms1', 'type': 'sentence', 'text': 'This is a test.', 'translation': '這是一個測試。', 'audioFile': ''},
    ];
    setState(() {
      _pronunciationItems = _practiceMode == 'word' ? mockWords : mockSentences;
      _isLoading = false;
      _currentIndex = 0;
      _pronunciationResult = null;
      _lastRecordingPath = null;
    });
  }


  // 切換練習模式
  Future<void> _togglePracticeMode() async {
    final newMode = _practiceMode == 'word' ? 'sentence' : 'word';
    setState(() {
      _practiceMode = newMode;
      // Data will be reloaded based on the new mode by _loadPronunciationData
    });
    await _loadPronunciationData(widget.book); // Reload data for the new mode
  }

  // 原音播放（TTS，統一語速）
  Future<void> _playOriginalAudio() async {
    if (_pronunciationItems.isEmpty || _currentIndex >= _pronunciationItems.length) {
      print("No item to play original audio for.");
      return;
    }
    final text = _pronunciationItems[_currentIndex]['text'];
    // 使用 TTS 播放原音，保持統一的語速控制
    await TtsService().speak(text, rate: _speechRate);
  }

  // 播放錄音
  Future<void> _playRecording() async {
    if (_lastRecordingPath == null) return;

    try {
      await _audioService.playRecording(_lastRecordingPath!);
    } catch (e) {
      print('播放錄音失敗: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('播放錄音失敗: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 開始錄音
  Future<void> _startRecording() async {
    if (_isRecording) return;

    final hasPermission = await _speechService.checkPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('無法獲取麥克風權限'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // 確保音頻已經停止
    await _audioService.stopAudio();

    final success = await _speechService.startRecording();
    if (success) {
      setState(() {
        _isRecording = true;
        _pronunciationResult = null;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('開始錄音失敗'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 停止錄音並評估
  Future<void> _stopRecordingAndEvaluate() async {
    if (!_isRecording) return;

    final recordingPath = await _speechService.stopRecording();
    setState(() {
      _isRecording = false;
      _lastRecordingPath = recordingPath;
    });

    if (recordingPath != null) {
      // 評估發音
      final result = await _speechService.evaluatePronunciation(
        recordingPath,
        _pronunciationItems[_currentIndex]['text'],
      );

      setState(() {
        _pronunciationResult = result;
      });
    }
  }

  // 下一個項目
  void _nextItem() {
    if (_pronunciationItems.isEmpty) return;
    if (_currentIndex < _pronunciationItems.length - 1) {
      setState(() {
        _currentIndex++;
        _pronunciationResult = null;
        _lastRecordingPath = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已經是最後一個練習項目了')),
      );
    }
  }

  // 上一個項目
  void _previousItem() {
    if (_pronunciationItems.isEmpty) return;
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _pronunciationResult = null;
        _lastRecordingPath = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已經是第一個練習項目了')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('發音練習'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_pronunciationItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('發音練習'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                '沒有可用的 ${_practiceMode == 'word' ? '單字' : '句子'} 練習項目',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('請嘗試其他書籍或練習模式。', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _togglePracticeMode, // Allow switching mode directly
                child: Text(_practiceMode == 'word' ? '嘗試句子練習' : '嘗試單字練習'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('返回書籍列表'),
              ),
            ],
          ),
        ),
      );
    }

    final currentItem = _pronunciationItems[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(_practiceMode == 'word' ? '單字發音練習' : '句子發音練習'),
        actions: [
          // 切換模式按鈕
          TextButton.icon(
            onPressed: _togglePracticeMode,
            icon: Icon(
              _practiceMode == 'word' ? Icons.short_text : Icons.subject,
              color: Colors.white,
            ),
            label: Text(
              _practiceMode == 'word' ? '切換到句子' : '切換到單字',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          // 語速切換按鈕
          SpeechRateButton(
            speechRates: _speechRates,
            speechRateLabels: _speechRateLabels,
            currentIndex: _speechRateIndex,
            onRateChanged: (index) {
              setState(() {
                _speechRateIndex = index;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 進度指示器
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _pronunciationItems.length,
            backgroundColor: Colors.grey.shade200,
            minHeight: 6,
          ),

          // 進度文本
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '${_currentIndex + 1} / ${_pronunciationItems.length}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 主要內容區域
          Expanded(
            child: Stack(
              children: [
                // 發音練習卡片
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade50, Colors.blue.shade100],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 文本顯示
                          Text(
                            currentItem['text'],
                            style: TextStyle(
                              fontSize: _practiceMode == 'word' ? 36 : 28,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 24),

                          // 翻譯
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              currentItem['translation'],
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // 音頻播放按鈕
                          ElevatedButton.icon(
                            onPressed:
                                _isPlayingOriginal ? null : _playOriginalAudio,
                            icon: Icon(
                              _isPlayingOriginal
                                  ? Icons.pause
                                  : Icons.volume_up,
                            ),
                            label: Text(
                              _isPlayingOriginal ? '播放中...' : '播放原音',
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // 如果有錄音，顯示播放錄音按鈕
                          if (_lastRecordingPath != null)
                            ElevatedButton.icon(
                              onPressed: _playRecording,
                              icon: const Icon(Icons.play_circle),
                              label: const Text('播放我的錄音'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 發音評估結果
                if (_pronunciationResult != null)
                  PronunciationFeedback(
                    result: _pronunciationResult!,
                    onClose: () {
                      setState(() {
                        _pronunciationResult = null;
                      });
                    },
                  ),
              ],
            ),
          ),

          // 底部控制區域
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 上一個按鈕
                IconButton(
                  onPressed: _previousItem,
                  icon: const Icon(Icons.arrow_back),
                  tooltip: '上一個',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    minimumSize: const Size(48, 48),
                  ),
                ),

                // 錄音按鈕
                GestureDetector(
                  onTap: _isRecording
                      ? _stopRecordingAndEvaluate
                      : _startRecording,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _isRecording ? Colors.red : Colors.blue,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording ? Colors.red : Colors.blue)
                              .withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: _isRecording
                        ? VoiceAnimation(
                            pulseAnimation: _pulseController,
                            color: Colors.white,
                          )
                        : const Icon(
                            Icons.mic,
                            color: Colors.white,
                            size: 36,
                          ),
                  ),
                ),

                // 下一個按鈕
                IconButton(
                  onPressed: _nextItem,
                  icon: const Icon(Icons.arrow_forward),
                  tooltip: '下一個',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    minimumSize: const Size(48, 48),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
