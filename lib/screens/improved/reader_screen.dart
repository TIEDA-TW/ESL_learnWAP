import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../../models/book_model.dart';
import '../../models/reading_mode.dart';
import '../../services/storage_service.dart';
import '../../services/improved/audio_service_bridge.dart';
import '../../services/improved/speech_service_bridge.dart';
import '../../services/improved/tts_service.dart';
import '../../services/translation_service.dart';
import '../../widgets/improved/interactive_text.dart';
import '../../widgets/improved/voice_animation.dart';
import '../../utils/audio_debug_helper.dart';
import '../../widgets/improved/reading_controls.dart';
import '../../widgets/improved/reading_mode_selector.dart';
import '../../widgets/speech_rate_button.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ImprovedReaderScreen extends StatefulWidget {
  final Book book;

  const ImprovedReaderScreen({
    Key? key,
    required this.book,
  }) : super(key: key);

  @override
  State<ImprovedReaderScreen> createState() => _ImprovedReaderScreenState();
}

class _ImprovedReaderScreenState extends State<ImprovedReaderScreen>
    with TickerProviderStateMixin {
  int _currentPage = 0;
  List<BookPage> _pages = [];
  bool _isLoading = true;
  bool _isTranslationLoading = false;
  ReadingMode _mode = ReadingMode.reading;
  String _selectedCategory = 'Sentence';

  // 縮放相關
  final TransformationController _transformationController =
      TransformationController();
  double _currentScale = 1.0;
  double _minScale = 0.5;
  double _maxScale = 3.0;

  // 圖片尺寸
  Size? _originalImageSize;

  // 服務實例
  late AudioServiceBridge _audioService;
  late SpeechServiceBridge _speechService;
  late StorageService _storageService;
  late TranslationService _translationService;
  double _playbackSpeed = 0.7;

  // 當前活動區域
  TextRegion? _activeRegion;

  // 錄音相關
  bool _isRecording = false;
  String? _lastRecordingPath;
  bool _showRecordButton = false;
  Duration _audioPlaybackDuration = Duration.zero;

  // 自動播放控制
  bool _isAutoPlaying = false;
  int _autoPlayIndex = 0;
  List<TextRegion> _autoPlayRegions = [];

  // 跟讀狀態
  bool _isPlayingOriginalAudio = false;
  bool _isPlayingRecordedAudio = false;
  bool _isInResultDialog = false; // 是否在結果對話框中
  bool _canStartRecording = false; // 是否可以開始錄音，使用者需先聯聚原音

  // 動畫控制器
  late AnimationController _pulseController;

  // 播放速度選單資料
  static const List<double> _speechRates = [0.5, 0.7, 1.0];
  static const List<String> _speechRateLabels = ['慢', '正常', '快'];
  int _speechRateIndex = 1; // 預設為 0.7 (正常)
  double get _speechRate => _speechRates[_speechRateIndex];

  // 取得目前頁面可用的分類（Sentence/Word）
  List<String> _getAvailableCategories() {
    if (_pages.isEmpty || _currentPage >= _pages.length) return ['Sentence'];
    final Set<String> cats = _pages[_currentPage].elements.map((e) => e.category).toSet();
    // 只允許 'Sentence' 和 'Word'
    final List<String> allowed = ['Sentence', 'Word'];
    return allowed.where((c) => cats.contains(c)).toList();
  }

  @override
  void initState() {
    super.initState();
    _audioService = AudioServiceBridge();
    _speechService = SpeechServiceBridge();
    _storageService = StorageService();
    _translationService = TranslationService();

    // 初始化動畫控制器
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _initializeScreen();

    // 設置音頻播放完成回調
    _audioService.setOnCompleteListener(() {
      if (_mode == ReadingMode.autoplay && _isAutoPlaying) {
        _playNextAutoplayItem();
      } else if (_mode == ReadingMode.speaking && _isPlayingOriginalAudio) {
        // 原始音頻播放完畢
        print('原始音頻播放完成回調觸發');
        if (mounted) {
          setState(() {
            _isPlayingOriginalAudio = false;
            _canStartRecording = true; // 原音播放完畢，現在可以開始錄音

            // 如果在對話框中，顯示一條提示
            if (_isInResultDialog) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('原音播放完成，現在可以開始錄音'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 1),
                ),
              );
            }

            // // 舊邏輯: 如果在跟讀結果對話框中，則播放錄音
            // if (_lastRecordingPath != null && _isInResultDialog) {
            //   _playRecordedAudio();
            // } else {
            //   // 否則顯示錄音按鈕 (此邏輯可能需要調整)
            //   _showRecordButton = true;
            // }
          });
        }
      } else if (_mode == ReadingMode.speaking && _isPlayingRecordedAudio) {
        // 錄音播放完畢
        if (mounted) {
          setState(() {
            _isPlayingRecordedAudio = false;
          });
        }
      }
    });
  }

  Future<void> _initializeScreen() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 初始化翻譯服務
      await _translationService.initialize();

      // 載入書籍資料
      final modelsPages =
          await _storageService.loadBookData(widget.book.dataPath);

      // 將 book_models.dart 中的 BookPage 轉換為 book_model.dart 中的 BookPage
      final convertedPages = modelsPages.map((modelPage) {
        // 將 BookElement 轉換為 TextRegion
        final elements = modelPage.elements
            .map((element) => TextRegion(
                  text: element.text,
                  category: element.category.toString().split('.').last,
                  audioFile: element.audioFile,
                  position: {
                    'x1': element.coordinates.x1,
                    'y1': element.coordinates.y1,
                    'x2': element.coordinates.x2,
                    'y2': element.coordinates.y2,
                  },
                  translation: element.translation,
                ))
            .toList();

        return BookPage(
          image: modelPage.image,
          elements: elements,
        );
      }).toList();

      setState(() {
        _pages = convertedPages;
        _isLoading = false;
      });

      // 載入圖片尺寸
      _loadImageSize();
    } catch (e) {
      print('初始化畫面失敗: $e');
      setState(() {
        _isLoading = false;
      });

      // 顯示錯誤
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('載入資料失敗: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _audioService.dispose();
    _speechService.dispose();
    _transformationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // 載入圖片尺寸
  Future<void> _loadImageSize() async {
    if (_pages.isEmpty) return;

    final image =
        AssetImage(widget.book.getImagePath(_pages[_currentPage].image));
    final imageStream = image.resolve(const ImageConfiguration());

    imageStream.addListener(ImageStreamListener((info, _) {
      if (mounted) {
        setState(() {
          _originalImageSize = Size(
            info.image.width.toDouble(),
            info.image.height.toDouble(),
          );
        });
      }
    }));
  }

  // 預載入翻譯
  Future<void> _preloadTranslations() async {
    if (_pages.isEmpty || !_translationService.isInitialized) return;

    setState(() {
      _isTranslationLoading = true;
    });

    try {
      // 首先嘗試從書籍數據載入專用翻譯
      await _translationService.loadTranslationsForBook(widget.book.dataPath);

      // 獲取當前頁面需要翻譯的文本
      final textsToTranslate = _pages[_currentPage]
          .elements
          .where((region) => region.category == _selectedCategory)
          .map((region) => region.text)
          .toList();

      // 批量翻譯
      final translations = _translationService.translateBatch(textsToTranslate);

      // 更新頁面元素的翻譯
      for (var element in _pages[_currentPage].elements) {
        if (element.category == _selectedCategory &&
            translations.containsKey(element.text)) {
          element.translation = translations[element.text];
        }
      }
    } catch (e) {
      print('預載入翻譯失敗: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isTranslationLoading = false;
        });
      }
    }
  }

  // 處理區域點擊
  void _handleRegionTap(TextRegion region) async {
    setState(() {
      _activeRegion = region;
      _canStartRecording = false; // 重置錄音狀態，需要聽完原音才能錄音
    });

    // 翻譯模式：如果尚未有翻譯，嘗試獲取翻譯
    if (_mode == ReadingMode.translation && region.translation == null) {
      try {
        // 先檢查區域本身是否已有翻譯字段（從JSON載入的）
        if (region.translation != null && region.translation!.isNotEmpty) {
          // 已有翻譯，不需要處理
        } else {
          // 使用翻譯服務獲取翻譯
          final translation = _translationService.translate(region.text);
          setState(() {
            region.translation = translation;
          });
        }
      } catch (e) {
        print('獲取翻譯失敗: $e');
      }
    }
    // 點讀模式
    else if (_mode == ReadingMode.reading) {
      // 點讀模式: 播放 TTS，先停止之前的 TTS 播放
      await TtsService().stop();
      _playTtsText(region.text);
    }
    // 跟讀模式
    else if (_mode == ReadingMode.speaking) {
      // 重置上一次的錄音路徑，確保新區域不會播放舊錄音
      _lastRecordingPath = null;
      // 記錄音頻時長，用於後續錄音
      try {
        // 記錄音頻開始播放的時間
        final startTime = DateTime.now();
        await _playTtsText(region.text);
        // 計算播放的時間長度
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        // 將時間長度存到_audioPlaybackDuration (確保至少有1秒)
        _audioPlaybackDuration = duration.inMilliseconds < 1000
            ? const Duration(seconds: 1)
            : duration;
      } catch (e) {
        print('跟讀模式播放音頻失敗: $e');
      }

      // 顯示跟讀對話框
      _showSpeakingDialog();
    }
    // 自動模式
    else if (_mode == ReadingMode.autoplay) {
      // 自動模式下不做特殊處理，避免干擾自動播放
      return;
    }
  }

  // 播放 TTS
  Future<void> _playTtsText(String text, {double? rate, String lang = 'en-US'}) async {
    await TtsService().stop();
    // 等待 150ms，確保 stop 完成，避免 Web TTS 無法立即 speak
    await Future.delayed(const Duration(milliseconds: 150));
    try {
      await TtsService().speak(text, rate: rate ?? _speechRate, lang: lang);
    } catch (e) {
      print('TTS 播放失敗: $e');
      // 可在這裡加入 UI 提示或更詳細的錯誤處理
    }
  }

  // 跟讀：播放原音(改為TTS)
  Future<void> _playOriginalAudio(Function? onComplete) async {
    try {
      if (_activeRegion == null) return;
      setState(() {
        _isPlayingOriginalAudio = true;
        _canStartRecording = true;
      });
      await _playTtsText(_activeRegion!.text);
      setState(() {
        _isPlayingOriginalAudio = false;
        _canStartRecording = true;
      });
      if (onComplete != null) {
        onComplete();
      }
    } catch (e) {
      print('播放原音失敗: $e');
      setState(() {
        _isPlayingOriginalAudio = false;
        _canStartRecording = true;
      });
      if (onComplete != null) {
        onComplete();
      }
    }
  }

  // 開始錄音
  Future<void> _startRecording() async {
    // 如果已經在錄音中，則停止錄音
    // (此處邏輯移到按鈕處判斷，此方法專注於開始)
    // if (_isRecording) {
    //   await _stopRecording();
    //   return;
    // }

    // 如果原音正在播放，不允許錄音
    if (_isPlayingOriginalAudio) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('請等原音播放完畢後再開始錄音'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isRecording) {
      await _stopRecording();
      return;
    }

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

    // 用對話框提示用戶準備錄音
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('準備錄音'),
        content: Text('請跟讀: "${_activeRegion?.text ?? ''}"'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _beginRecording();
            },
            child: Text('開始錄音'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('取消'),
          ),
        ],
      ),
    );
  }

  // 開始錄音處理
  Future<void> _beginRecording() async {
    print('開始錄音處理...');

    // 確保音頻已經停止
    await _audioService.stopAudio();

    // 確保錄音時間至少為2秒
    if (_audioPlaybackDuration.inMilliseconds < 1000) {
      _audioPlaybackDuration = const Duration(seconds: 2);
    }

    final success = await _speechService.startRecording();
    print('錄音開始結果: $success');

    if (success) {
      setState(() {
        _isRecording = true;
        _showRecordButton = true; // 確保錄音按鈕顯示
      });
      print('錄音狀態已更新: _isRecording = $_isRecording');
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

  // 停止錄音
  Future<void> _stopRecording() async {
    if (!_isRecording || _activeRegion == null) {
      print('停止錄音失敗: 未在錄音中或沒有活動區域');
      return;
    }

    print('停止錄音中...');
    final recordingPath = await _speechService.stopRecording();
    print('錄音路徑: $recordingPath');

    setState(() {
      _isRecording = false;
      _lastRecordingPath = recordingPath;
      _showRecordButton = false;
    });
    print('錄音已停止，狀態已更新: _isRecording = $_isRecording');

    // 確保錄音路徑有效
    if (recordingPath != null && recordingPath.isNotEmpty) {
      print('錄音成功，準備播放');
    } else {
      print('錄音失敗或路徑為空');
    }

    if (recordingPath != null) {
      print('準備播放原始音頻和錄音...');
      // 確保音頻已經停止
      await _audioService.stopAudio();

      // 先播放原音
      setState(() {
        _isPlayingOriginalAudio = true;
      });

      try {
        // 播放原始音頻
        print('播放原始音頻: ${_activeRegion!.audioFile}');
        await _playTtsText(_activeRegion!.text);

        // 原音播放完成，更新狀態
        if (mounted) {
          setState(() {
            _isPlayingOriginalAudio = false;
          });
        }

        // 增加間隔時間到 1 秒
        print('原始音頻播放完成，等待 1 秒後播放錄音...');
        await Future.delayed(const Duration(seconds: 1));

        // 播放錄音
        if (_lastRecordingPath != null && mounted) {
          print('開始播放錄音: $_lastRecordingPath');
          try {
            setState(() {
              _isPlayingRecordedAudio = true;
            });
            await _audioService.playRecording(_lastRecordingPath!);
            print('錄音播放完成');
            if (mounted) {
              setState(() {
                _isPlayingRecordedAudio = false;
              });
            }
          } catch (e) {
            print('播放錄音失敗: $e');
            if (mounted) {
              setState(() {
                _isPlayingRecordedAudio = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('播放錄音失敗: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      } catch (e) {
        print('播放原始音頻失敗: $e');
        if (mounted) {
          setState(() {
            _isPlayingOriginalAudio = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('播放原始音頻失敗: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      print('錄音失敗');
    }
  }

  // 顯示跟讀對話框
  Future<void> _showSpeakingDialog() async {
    if (_activeRegion == null) return;

    // 設置狀態為對話框打開
    setState(() {
      _isInResultDialog = true;
      _canStartRecording = true; // 初始狀態允許錄音，不再需要先播放原音
    });

    // 顯示跟讀對話框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final screenWidth = MediaQuery.of(context).size.width;
          final double fontSize = screenWidth < 500 ? 30 : 60;
          final double iconSize = screenWidth < 500 ? 40 : 80;

          return AlertDialog(
            titlePadding: const EdgeInsets.only(left: 20, top: 20, right: 20),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '跟讀',
                    style: TextStyle(fontSize: fontSize * 0.5, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: fontSize * 0.5),
                  onPressed: () {
                    _audioService.stopAudio();
                    if (_isRecording) {
                      _speechService.stopRecording();
                    }
                    setState(() {
                      _isPlayingOriginalAudio = false;
                      _isPlayingRecordedAudio = false;
                      _isRecording = false;
                      _isInResultDialog = false;
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            contentPadding: const EdgeInsets.all(20),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9,
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 文字區域（可滾動）
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Scrollbar(
                        child: SingleChildScrollView(
                          child: Text(
                            '${_activeRegion?.text ?? ""}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: fontSize * 0.8,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  // 控制按鈕保持在下方固定位置
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.headphones, size: iconSize),
                        tooltip: '播放錄音',
                        onPressed: (_lastRecordingPath != null &&
                                !_isPlayingOriginalAudio &&
                                !_isRecording &&
                                !_isPlayingRecordedAudio)
                            ? () {
                                setState(() {
                                  _isPlayingRecordedAudio = true;
                                });
                                _playRecordedAudio();
                              }
                            : null,
                        color: (_lastRecordingPath != null &&
                                !_isPlayingOriginalAudio &&
                                !_isRecording &&
                                !_isPlayingRecordedAudio)
                            ? Colors.orange
                            : Colors.grey,
                      ),
                      SizedBox(width: iconSize * 0.375),
                      IconButton(
                        icon: Icon(Icons.volume_up, size: iconSize),
                        tooltip: '播放原音',
                        onPressed: _isPlayingOriginalAudio ||
                                _isRecording ||
                                _isPlayingRecordedAudio
                            ? null
                            : () {
                                setState(() {
                                  _isPlayingOriginalAudio = true;
                                  _isPlayingRecordedAudio = false;
                                  _canStartRecording = false;
                                });
                                _playTtsText(_activeRegion!.text);
                              },
                        color: (_isPlayingOriginalAudio ||
                                _isRecording ||
                                _isPlayingRecordedAudio)
                            ? Colors.grey
                            : Colors.blue,
                      ),
                      const SizedBox(width: 30),
                      IconButton(
                        icon: Icon(
                          _isRecording ? Icons.stop : Icons.mic,
                          size: iconSize,
                        ),
                        tooltip: _isRecording ? '停止錄音' : '開始錄音',
                        onPressed: (_isPlayingOriginalAudio ||
                                _isPlayingRecordedAudio ||
                                !_canStartRecording)
                            ? null
                            : () {
                                if (_isRecording) {
                                  _stopRecording().then((_) {
                                    setDialogState(() {
                                      _isRecording = false;
                                    });
                                  });
                                } else {
                                  _beginRecording().then((_) {
                                    setDialogState(() {
                                      _isRecording = true;
                                    });
                                  });
                                }
                              },
                        color: _isRecording
                            ? Colors.red
                            : (_canStartRecording ? Colors.green : Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).then((_) {
      // 對話框關閉時停止音頻和錄音
      _audioService.stopAudio();
      if (_isRecording) {
        _speechService.stopRecording();
      }
      setState(() {
        _isPlayingOriginalAudio = false;
        _isPlayingRecordedAudio = false;
        _isRecording = false;
        _isInResultDialog = false;
      });
    });
  }

  // 播放錄音
  Future<void> _playRecordedAudio() async {
    if (_lastRecordingPath == null) return;

    setState(() {
      _isPlayingOriginalAudio = false;
      _isPlayingRecordedAudio = true;
    });

    try {
      // 播放錄音
      print('開始播放錄音: $_lastRecordingPath');
      print('錄音路徑類型: ${kIsWeb ? "Web URL" : "本地文件"}');

      // 確保路徑有效
      if (_lastRecordingPath!.isEmpty) {
        print('錯誤: 錄音路徑為空');
        throw Exception('錄音路徑為空');
      }

      // Web平台特殊處理
      if (kIsWeb) {
        print('Web平台播放錄音URL: $_lastRecordingPath');
        if (_lastRecordingPath!.endsWith('.webm') ||
            _lastRecordingPath!.startsWith('blob:')) {
          print('檢測到WebM格式錄音，使用Web Audio API播放');
          await _audioService.playRecording(_lastRecordingPath!);
        } else {
          print('非WebM格式，嘗試轉換播放');
          await _audioService.playRecording(_lastRecordingPath!);
        }
      } else {
        // 非Web平台，檢查文件是否存在
        final file = File(_lastRecordingPath!);
        final exists = await file.exists();
        if (!exists) {
          print('錯誤: 錄音檔案不存在: $_lastRecordingPath');
          throw Exception('錄音檔案不存在');
        }

        final fileSize = await file.length();
        print('錄音檔案大小: $fileSize bytes');
        if (fileSize <= 0) {
          print('錯誤: 錄音檔案大小為零');
          throw Exception('錄音檔案大小為零');
        }

        // 播放本地錄音文件
        await _audioService.playRecording(_lastRecordingPath!);
      }

      print('錄音播放完成');
      if (mounted) {
        setState(() {
          _isPlayingRecordedAudio = false;
        });
      }
    } catch (e) {
      print('播放錄音失敗: $e');
      // 顯示更友好的錯誤訊息
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(kIsWeb ? '播放錄音失敗，請確保瀏覽器支持WebM格式' : '播放錄音失敗，請重新錄音'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() {
          _isPlayingRecordedAudio = false;
        });
      }
      // 重新拋出錯誤以便上層處理
      rethrow;
    }
  }

  // 對區域進行排序 (左側優先，然後從上到下)
  List<TextRegion> _sortRegionsForAutoplay(List<TextRegion> regions) {
    if (regions.isEmpty) return [];

    // 假設圖片寬度的中點是左右區域的分界線
    final midX = _originalImageSize != null ? _originalImageSize!.width / 2 : 0;

    // 分離左右區域
    final leftRegions =
        regions.where((region) => region.position['x1']! < midX).toList();
    final rightRegions =
        regions.where((region) => region.position['x1']! >= midX).toList();

    // 分別按垂直位置排序
    leftRegions.sort((a, b) => a.position['y1']!.compareTo(b.position['y1']!));
    rightRegions.sort((a, b) => a.position['y1']!.compareTo(b.position['y1']!));

    // 合併左右區域
    return [...leftRegions, ...rightRegions];
  }

  // 開始自動播放
  void _startAutoplay() async {
    if (_isAutoPlaying) return;

    // 獲取當前頁面上的所有區域
    final regions = _pages[_currentPage]
        .elements
        .where((region) => region.category == _selectedCategory)
        .toList();

    if (regions.isEmpty) return;

    // 按左右和上下順序排序區域
    final sortedRegions = _sortRegionsForAutoplay(regions);

    setState(() {
      _isAutoPlaying = true;
      _autoPlayRegions = sortedRegions;
      _autoPlayIndex = 0;
      _activeRegion = sortedRegions[0];
    });

    // 設置 TTS 完成事件處理器
    TtsService().setCompletionHandler(() {
      if (_isAutoPlaying && mounted) {
        _playNextAutoplayItem();
      }
    });

    // 播放第一個區域
    await _playTtsText(sortedRegions[0].text);
  }

  // 播放下一個自動播放項目
  void _playNextAutoplayItem() async {
    if (!_isAutoPlaying || _autoPlayRegions.isEmpty || !mounted) return;

    // 移動到下一個區域
    _autoPlayIndex += 1;

    // 如果已經播放到最後一個，結束自動播放
    if (_autoPlayIndex >= _autoPlayRegions.length) {
      setState(() {
        _isAutoPlaying = false;
        _autoPlayIndex = 0;
      });
      return;
    }

    // 設置當前活動區域並播放
    setState(() {
      _activeRegion = _autoPlayRegions[_autoPlayIndex];
    });

    // 等待短暫延遲後播放下一個
    await Future.delayed(const Duration(milliseconds: 500));
    await _playTtsText(_activeRegion!.text);
  }

  // 停止自動播放
  void _stopAutoplay() {
    if (!mounted) return;
    
    setState(() {
      _isAutoPlaying = false;
      _autoPlayIndex = 0;
    });
    
    // 解除 TTS 完成事件
    TtsService().setCompletionHandler(null);
  }

  // 切換閱讀模式
  void _changeReadingMode(ReadingMode mode) {
    if (_mode == mode) return;

    setState(() {
      _mode = mode;
      _activeRegion = null;
      _showRecordButton = false;

      // 停止任何進行中的播放
      if (_isAutoPlaying) {
        _stopAutoplay();
      }
    });

    // 如果切換到翻譯模式，預加載翻譯
    if (mode == ReadingMode.translation) {
      _preloadTranslations();
    }
  }

  // 構建文字區域覆蓋層
  Widget _buildTextRegionOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_originalImageSize == null) return Container();

        // 計算縮放比例
        final double scaleX = constraints.maxWidth / _originalImageSize!.width;
        final double scaleY =
            constraints.maxHeight / _originalImageSize!.height;
        final double scale = scaleX < scaleY ? scaleX : scaleY;

        // 計算圖片實際顯示的大小
        final double displayWidth = _originalImageSize!.width * scale;
        final double displayHeight = _originalImageSize!.height * scale;

        // 計算圖片在容器中的偏移量（置中對齊）
        final double offsetX = (constraints.maxWidth - displayWidth) / 2;
        final double offsetY = (constraints.maxHeight - displayHeight) / 2;

        // 根據模式過濾區域
        final filteredRegions = _pages[_currentPage]
            .elements
            .where((region) => region.category == _selectedCategory)
            .toList();

        return Stack(
          children: filteredRegions.map((region) {
            // 是否高亮顯示當前選中區域
            final bool isHighlighted = _activeRegion == region;
            // 是否是自動播放中的當前項目
            final bool isCurrentAutoplay = _isAutoPlaying &&
                _autoPlayRegions.isNotEmpty &&
                _autoPlayRegions[_autoPlayIndex] == region;

            return ImprovedInteractiveTextRegion(
              region: region,
              scale: scale,
              offset: Offset(offsetX, offsetY),
              onTap: _handleRegionTap,
              showTranslation: _mode == ReadingMode.translation,
              isHighlighted: isHighlighted,
              isAutoplay: isCurrentAutoplay,
              pulseAnimation: _pulseController,
              speechRate: _speechRate,
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.book.name),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_pages.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.book.name),
        ),
        body: const Center(
          child: Text('無法載入書籍資料'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        // 將標題、下拉選單和頁數放在 Row 中
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 書本名稱
            SizedBox(width: 4),
            Text(
              widget.book.name,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            SizedBox(width: 8),
            // 類別切換按鈕（SVG自訂icon）
            Container(
              alignment: Alignment.center,
              margin: EdgeInsets.only(bottom: 2),
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                icon: _selectedCategory == 'Sentence'
                    ? Icon(Icons.short_text, color: Colors.white, size: 22)
                    : SvgPicture.asset(
                        'assets/icons/word_icon.svg',
                        width: 22,
                        height: 22,
                        colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
                      ),
                tooltip: _selectedCategory == 'Sentence' ? '切換為單字' : '切換為句子',
                onPressed: () {
                  setState(() {
                    _selectedCategory = _selectedCategory == 'Sentence' ? 'Word' : 'Sentence';
                    _activeRegion = null;
                    if (_isAutoPlaying) _stopAutoplay();
                    if (_mode == ReadingMode.translation) _preloadTranslations();
                  });
                },
              ),
            ),
            // Spacer 將右側按鈕推到最右邊
            Spacer(),
          ],
        ),
        actions: [
          // 常駐：點擊、跟讀
          IconButton(
            icon: Icon(Icons.touch_app, size: 22, color: _mode == ReadingMode.reading ? Theme.of(context).colorScheme.primary : Colors.grey.shade600),
            tooltip: '點讀',
            onPressed: () => _changeReadingMode(ReadingMode.reading),
          ),
          IconButton(
            icon: Icon(Icons.mic, size: 22, color: _mode == ReadingMode.speaking ? Theme.of(context).colorScheme.primary : Colors.grey.shade600),
            tooltip: '跟讀',
            onPressed: () => _changeReadingMode(ReadingMode.speaking),
          ),
          // 更多選單（PopupMenuButton）
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'translation') {
                _changeReadingMode(ReadingMode.translation);
              } else if (value == 'autoplay') {
                _changeReadingMode(ReadingMode.autoplay);
              } else if (value == 'speechrate') {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('切換播放速度'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(_speechRates.length, (i) => ListTile(
                        title: Text(_speechRateLabels[i]),
                        trailing: _speechRateIndex == i ? Icon(Icons.check) : null,
                        onTap: () {
                          setState(() {
                            _speechRateIndex = i;
                            _playbackSpeed = _speechRates[_speechRateIndex];
                          });
                          Navigator.pop(context);
                        },
                      )),
                    ),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'translation',
                child: ListTile(
                  leading: Icon(Icons.translate),
                  title: Text('翻譯'),
                ),
              ),
              PopupMenuItem(
                value: 'autoplay',
                child: ListTile(
                  leading: Icon(Icons.play_circle_outline),
                  title: Text('全文自動播放'),
                ),
              ),
              PopupMenuItem(
                value: 'speechrate',
                child: ListTile(
                  leading: Icon(Icons.speed),
                  title: Text('切換播放速度'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 圖片和文字框顯示區域
          Expanded(
            child: Stack(
              children: [
                // 圖片和文字區域
                InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: _minScale,
                  maxScale: _maxScale,
                  onInteractionEnd: (details) {
                    setState(() {
                      _currentScale =
                          _transformationController.value.getMaxScaleOnAxis();
                    });
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        widget.book.getImagePath(_pages[_currentPage].image),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          print('DEBUG: ReaderScreen Image Error - Book ID: ${widget.book.id}, Path: ' + widget.book.getImagePath(_pages[_currentPage].image) + ', Error: $error');
                          return Center(
                            child: Text(
                              '找不到圖片: ' + widget.book.getImagePath(_pages[_currentPage].image),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red, fontSize: 16),
                            ),
                          );
                        },
                      ),
                      _buildTextRegionOverlay(),
                    ],
                  ),
                ),

                // 上一頁按鈕 - 移至圖片顯示區左側
                if (_currentPage > 0)
                  Positioned(
                    left: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios,
                              color: Colors.white),
                          onPressed: () {
                            _audioService.stopAudio();
                            setState(() {
                              _currentPage--;
                              _activeRegion = null;
                              _isAutoPlaying = false;
                              _loadImageSize();

                              // 如果是翻譯模式，重新載入翻譯
                              if (_mode == ReadingMode.translation) {
                                _preloadTranslations();
                              }
                            });
                          },
                          tooltip: '上一頁',
                        ),
                      ),
                    ),
                  ),

                // 下一頁按鈕 - 移至圖片顯示區右側
                if (_currentPage < _pages.length - 1)
                  Positioned(
                    right: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_forward_ios,
                              color: Colors.white),
                          onPressed: () {
                            _audioService.stopAudio();
                            setState(() {
                              _currentPage++;
                              _activeRegion = null;
                              _isAutoPlaying = false;
                              _loadImageSize();

                              // 如果是翻譯模式，重新載入翻譯
                              if (_mode == ReadingMode.translation) {
                                _preloadTranslations();
                              }
                            });
                          },
                          tooltip: '下一頁',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 閱讀控制區域
          ReadingControls(
            currentPage: _currentPage,
            totalPages: _pages.length,
            currentScale: _currentScale,
            isAutoPlaying: _isAutoPlaying,
            readingMode: _mode,
            onZoomIn: () {
              final newScale =
                  (_currentScale + 0.2).clamp(_minScale, _maxScale);
              _transformationController.value = Matrix4.identity()
                ..scale(newScale);
              setState(() {
                _currentScale = newScale;
              });
            },
            onZoomOut: () {
              final newScale =
                  (_currentScale - 0.2).clamp(_minScale, _maxScale);
              _transformationController.value = Matrix4.identity()
                ..scale(newScale);
              setState(() {
                _currentScale = newScale;
              });
            },
            onResetZoom: () {
              _transformationController.value = Matrix4.identity();
              setState(() {
                _currentScale = 1.0;
              });
            },
            onPreviousPage: _currentPage > 0
                ? () {
                    _audioService.stopAudio();
                    setState(() {
                      _currentPage--;
                      _activeRegion = null;
                      _isAutoPlaying = false;
                      _loadImageSize();

                      // 如果是翻譯模式，重新載入翻譯
                      if (_mode == ReadingMode.translation) {
                        _preloadTranslations();
                      }
                    });
                  }
                : null,
            onNextPage: _currentPage < _pages.length - 1
                ? () {
                    _audioService.stopAudio();
                    setState(() {
                      _currentPage++;
                      _activeRegion = null;
                      _isAutoPlaying = false;
                      _loadImageSize();

                      // 如果是翻譯模式，重新載入翻譯
                      if (_mode == ReadingMode.translation) {
                        _preloadTranslations();
                      }
                    });
                  }
                : null,
            onStartAutoplay: _mode == ReadingMode.autoplay && !_isAutoPlaying
                ? _startAutoplay
                : null,
            onStopAutoplay: _isAutoPlaying ? _stopAutoplay : null,
          ),
        ],
      ),
      // 跟讀模式下的錄音按鈕
      floatingActionButton: _mode == ReadingMode.speaking && _showRecordButton
          ? FloatingActionButton(
              backgroundColor: _isRecording ? Colors.red : Colors.green,
              child: Icon(_isRecording ? Icons.stop : Icons.mic),
              onPressed: _isRecording ? _stopRecording : _startRecording,
            )
          : null,
    );
  }
}
