import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:idb_shim/idb_browser.dart';
import 'package:idb_shim/idb_shim.dart';

/// Web安全的語音服務，處理Web平台上的麥克風權限和錄音功能
class WebSafeSpeechService {
  // 錄音狀態
  bool _isRecording = false;
  String? _recordingUrl;

  // 取得錄音狀態
  bool get isRecording => _isRecording;

  // 取得錄音URL
  String? get recordingUrl => _recordingUrl;

  // IndexedDB 相關
  static const String _dbName = 'audio_recordings_db';
  static const String _storeName = 'recordings';
  static const String _recordingKey = 'latest_recording';
  Database? _db;

  // 聲音水平變化回調
  Function(double)? _onAmplitudeChanged;

  // 錄音相關
  html.MediaRecorder? _mediaRecorder;
  List<html.Blob> _audioChunks = [];
  StreamController<double>? _amplitudeController;

  // 單例模式
  static final WebSafeSpeechService _instance = WebSafeSpeechService._internal();

  factory WebSafeSpeechService() {
    return _instance;
  }

  WebSafeSpeechService._internal() {
    _initDatabase();
  }

  // 初始化 IndexedDB 數據庫
  Future<void> _initDatabase() async {
    try {
      print('初始化 IndexedDB 數據庫...');
      final idbFactory = getIdbFactory();
      
      if (idbFactory == null) {
        print('無法得到 IdbFactory，可能不在 Web 環境');
        return;
      }
      
      // 打開數據庫，如果不存在則創建
      _db = await idbFactory.open(_dbName, version: 1, onUpgradeNeeded: (VersionChangeEvent event) {
        final db = event.database;
        // 創建存儲錄音檔案的存儲區
        db.createObjectStore(_storeName);
        print('創建 IndexedDB 存儲區成功: $_storeName');
      });
      
      print('IndexedDB 數據庫初始化成功: $_dbName');
    } catch (e) {
      print('IndexedDB 初始化失敗: $e');
    }
  }

  // 確保數據庫已經初始化
  Future<Database> _ensureDbOpen() async {
    if (_db == null) {
      await _initDatabase();
      if (_db == null) {
        throw Exception('無法初始化 IndexedDB 數據庫');
      }
    }
    return _db!;
  }

  // 檢查麥克風權限
  Future<bool> checkPermission() async {
    try {
      // 在Web平台上，我們需要明確請求麥克風權限
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        print('瀏覽器不支持mediaDevices API');
        return false;
      }

      // 嘗試獲取麥克風權限
      await mediaDevices.getUserMedia({'audio': true});
      return true;
    } catch (e) {
      print('獲取麥克風權限失敗: $e');
      return false;
    }
  }

  // 開始錄音
  Future<bool> startRecording() async {
    if (_isRecording) {
      print('已經在錄音中，忽略重複請求');
      return true;
    }

    try {
      print('WebSafeSpeechService: 開始錄音...');
      // 清除之前的錄音數據
      _audioChunks = [];
      _recordingUrl = null;

      // 獲取麥克風權限
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        print('瀏覽器不支持mediaDevices API');
        return false;
      }

      // 請求麥克風訪問權限
      print('請求麥克風訪問權限...');
      final stream = await mediaDevices.getUserMedia({'audio': true});
      print('成功獲取麥克風權限');

      try {
        // 指定錄音格式為WebM (瀏覽器普遍支援)
        _mediaRecorder = html.MediaRecorder(stream, {
          'mimeType': 'audio/webm',
          'audioBitsPerSecond': 128000
        });
        print('成功創建 MediaRecorder 實例');
      } catch (e) {
        print('創建 MediaRecorder 失敗，嘗試使用預設格式: $e');
        _mediaRecorder = html.MediaRecorder(stream);
        print('成功使用預設格式創建 MediaRecorder');
      }

      // 設置數據可用時的回調
      _mediaRecorder!.addEventListener('dataavailable', (html.Event event) {
        print('dataavailable 事件觸發...');
        final dataEvent = event as html.BlobEvent;
        if (dataEvent.data != null && dataEvent.data!.size > 0) {
          _audioChunks.add(dataEvent.data!);
          print('收到音頻數據塊，大小: ${dataEvent.data!.size} bytes');
        } else {
          print('警告: 收到空的數據塊或大小為0');
        }
      });

      // 設置錄音停止時的回調
      _mediaRecorder!.addEventListener('stop', (html.Event _) {
        print('錄音停止事件觸發，數據塊數量: ${_audioChunks.length}');
        if (_audioChunks.isEmpty) {
          print('警告: 沒有收到任何音頻數據塊');
          return;
        }
        
        try {
          // 創建Blob URL (使用WebM格式並使用.webm副檔名)
          final blob = html.Blob(_audioChunks, 'audio/webm');
          print('成功創建 Blob，大小: ${blob.size} bytes');
          _recordingUrl = html.Url.createObjectUrlFromBlob(blob);
          print('錄音完成 (WebM格式)，URL: $_recordingUrl');
          
          // 將錄音存入 IndexedDB
          _saveRecordingToIndexedDB(blob);
          
          // 測試播放錄音
          _testPlayRecording();
        } catch (e) {
          print('創建 Blob URL失敗: $e');
        }
      });

      // 開始錄音 - 請求數據片段間隔為100毫秒以確保數據流
      print('開始錄音，指定數據片段間隔為100毫秒...');
      _mediaRecorder!.start(100); // 每100毫秒請求一次數據
      _isRecording = true;

      // 模擬聲音水平變化
      _startAmplitudeSimulation();
      
      print('錄音開始完成，等待數據...');
      return true;
    } catch (e) {
      print('開始錄音失敗: $e');
      return false;
    }
  }

  // 模擬聲音水平變化
  void _startAmplitudeSimulation() {
    _amplitudeController = StreamController<double>();

    // 每200毫秒生成一個隨機振幅值
    Timer.periodic(Duration(milliseconds: 200), (timer) {
      if (!_isRecording) {
        timer.cancel();
        _amplitudeController?.close();
        return;
      }

      // 生成0.0到1.0之間的隨機值
      final random = DateTime.now().millisecondsSinceEpoch % 100 / 100;
      // 加上一些變化，使其在0.1到0.8之間
      final amplitude = 0.1 + random * 0.7;

      // 添加到流中
      _amplitudeController?.add(amplitude);

      // 調用回調函數
      if (_onAmplitudeChanged != null) {
        _onAmplitudeChanged!(amplitude);
      }
    });
  }

  // 獲取聲音水平流
  Stream<double>? getAmplitudeStream() {
    return _amplitudeController?.stream;
  }

  // 設置聲音水平變化回調
  void setOnAmplitudeChanged(Function(double) onAmplitudeChanged) {
    _onAmplitudeChanged = onAmplitudeChanged;
  }

  // 停止錄音
  Future<String?> stopRecording() async {
    if (!_isRecording || _mediaRecorder == null) {
      print('非錄音狀態，無法停止');
      return null;
    }

    try {
      print('停止Web錄音...');
      
      // 手動請求數據從媒體記錄器 (確保獲取所有錄音數據)
      _mediaRecorder!.requestData();
      
      // 停止錄音
      _mediaRecorder!.stop();
      _isRecording = false;
      print('已發送停止錄音命令');

      // 等待錄音URL生成
      int attempts = 0;
      while (_recordingUrl == null && attempts < 20) {
        // 增加等待時間
        await Future.delayed(Duration(milliseconds: 200));
        attempts++;
        if (attempts % 5 == 0) {
          print('等待錄音URL生成，已嘗試 $attempts 次');
        }
      }

      if (_recordingUrl != null) {
        print('成功生成錄音URL: $_recordingUrl');
      } else {
        // 嘗試從IndexedDB讀取上一次錄製的音頻
        print('錄音URL生成失敗，嘗試從IndexedDB讀取...');
        _recordingUrl = await getRecordingFromIndexedDB();
        if (_recordingUrl != null) {
          print('從IndexedDB成功讀取錄音URL');
        } else {
          print('無法獲取錄音URL');
        }
      }

      return _recordingUrl;
    } catch (e) {
      print('停止錄音失敗: $e');
      // 嘗試從IndexedDB讀取上一次錄製的音頻
      try {
        print('嘗試從IndexedDB讀取上一次錄音...');
        _recordingUrl = await getRecordingFromIndexedDB();
        if (_recordingUrl != null) {
          print('從IndexedDB成功讀取錄音URL');
          return _recordingUrl;
        }
      } catch (idbError) {
        print('從IndexedDB讀取錄音也失敗: $idbError');
      }
      return null;
    }
  }

  // 評分發音 (模擬功能)
  Future<Map<String, dynamic>> evaluatePronunciation(
      String recordingPath, String targetText) async {
    // 模擬評分功能
    await Future.delayed(Duration(seconds: 1));

    // 使用時間毫秒作為隨機因子
    final time = DateTime.now().millisecondsSinceEpoch;
    final lastDigit = time % 10;
    final accuracy = 75.0 + lastDigit; // 75-84分之間

    // 根據分數給出具體建議
    String detailedFeedback;
    if (accuracy > 90) {
      detailedFeedback = '發音非常標準，繼續保持！';
    } else if (accuracy > 80) {
      detailedFeedback = '發音很好，注意語調的起伏。';
    } else if (accuracy > 70) {
      detailedFeedback = '發音不錯，可以再清晰一些。';
    } else if (accuracy > 60) {
      detailedFeedback = '基本發音正確，需要多練習。';
    } else {
      detailedFeedback = '需要更多練習，注意聽清原音。';
    }

    return {
      'score': accuracy,
      'feedback': accuracy > 80
          ? '發音很好!'
          : accuracy > 60
              ? '發音不錯，繼續練習!'
              : '請再試一次!',
      'detailedFeedback': detailedFeedback,
      'recognizedText': targetText, // 模擬識別出的文字
      'perfectMatch': accuracy > 90, // 是否完美匹配
    };
  }

  // 將錄音存入 IndexedDB
  Future<void> _saveRecordingToIndexedDB(html.Blob blob) async {
    try {
      print('將錄音存入 IndexedDB...');
      final db = await _ensureDbOpen();
      
      // 讀取 Blob 數據
      final reader = html.FileReader();
      final completer = Completer<Uint8List>();
      
      reader.onLoad.listen((event) {
        final Uint8List result = reader.result as Uint8List;
        completer.complete(result);
      });
      
      reader.onError.listen((event) {
        print('讀取 Blob 數據失敗: ${reader.error}');
        completer.completeError('Failed to read blob data');
      });
      
      reader.readAsArrayBuffer(blob);
      final Uint8List audioData = await completer.future;
      print('讀取 Blob 數據成功，數據大小: ${audioData.length} bytes');
      
      // 在事務中存入錄音數據
      final transaction = db.transaction(_storeName, 'readwrite');
      final store = transaction.objectStore(_storeName);
      
      // 將錄音數據以及 MIME 類型存入數據庫
      await store.put({
        'data': audioData,
        'mimeType': 'audio/webm',
        'timestamp': DateTime.now().millisecondsSinceEpoch
      }, _recordingKey);
      
      print('錄音已成功存入 IndexedDB');
    } catch (e) {
      print('存入錄音到 IndexedDB 失敗: $e');
    }
  }

  // 從 IndexedDB 中讀取錄音 (公開方法)
  Future<String?> getRecordingFromIndexedDB() async {
    try {
      print('從 IndexedDB 讀取錄音...');
      final db = await _ensureDbOpen();
      
      final transaction = db.transaction(_storeName, 'readonly');
      final store = transaction.objectStore(_storeName);
      
      // 檢查是否存在錄音
      final recordingData = await store.getObject(_recordingKey);
      
      if (recordingData == null) {
        print('IndexedDB 中沒有存儲錄音');
        return null;
      }
      
      // 從讀取的對象中提取數據和 MIME 類型 (使用類型轉換)
      final Map<String, dynamic> dataMap = recordingData as Map<String, dynamic>;
      final Uint8List audioData = dataMap['data'] as Uint8List;
      final String mimeType = dataMap['mimeType'] as String? ?? 'audio/webm';
      
      print('從 IndexedDB 讀取到錄音數據，大小: ${audioData.length} bytes, 格式: $mimeType');
      
      // 創建 Blob 後生成 URL
      final blob = html.Blob([audioData], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      print('已從 IndexedDB 讀取錄音，創建 URL: $url');
      return url;
    } catch (e) {
      print('從 IndexedDB 讀取錄音失敗: $e');
      return null;
    }
  }

  // 測試播放錄音
  void _testPlayRecording() {
    if (_recordingUrl == null) {
      print('無法測試播放: 錄音URL為空');
      return;
    }

    try {
      final audio = html.AudioElement(_recordingUrl);
      audio.autoplay = false; // 避免干擾用戶，不自動播放
      audio.controls = true;
      audio.style.position = 'absolute';
      audio.style.left = '-9999px';
      
      html.document.body?.append(audio);
      print('創建音頻元素測試播放準備: ${_recordingUrl}');
      
      audio.onError.listen((e) {
        print('播放錄音失敗: ${e}');
        print('詳細錯誤: ${audio.error?.message}');
        print('建議: 請確保瀏覽器支援WebM音頻格式 (Chrome/Firefox/Edge)');
        audio.remove();
      });
      
      audio.onEnded.listen((_) {
        print('測試音頻播放完成');
        audio.remove();
      });
    } catch (e) {
      print('測試播放錄音失敗: $e');
      print('完整錯誤訊息: ${e.toString()}');
    }
  }

  // 釋放資源
  void dispose() {
    if (_mediaRecorder != null && _isRecording) {
      try {
        _mediaRecorder!.stop();
      } catch (e) {
        print('停止錄音失敗: $e');
      }
    }

    _isRecording = false;
    _amplitudeController?.close();
  }
}