import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_progress.dart';
import '../constants/app_constants.dart';

class ImprovedUserService {
  // 單例模式
  static final ImprovedUserService _instance = ImprovedUserService._internal();
  factory ImprovedUserService() => _instance;
  ImprovedUserService._internal();

  // 用戶數據
  UserProgress? _userProgress;
  String _userId = 'default_user';
  String? _userName;
  late SharedPreferences _prefs;

  // 初始化服務
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    
    if (kIsWeb) {
      _userProgress = UserProgress.initial(_userId);
      return;
    }

    _userProgress = await _loadUserProgress();
    if (_userProgress == null) {
      _userProgress = UserProgress.initial(_userId);
      await _saveUserProgress();
    }

    await _loadUserName();
  }

  // 用戶名稱相關方法
  Future<String?> getUserName() async {
    if (_userName == null) {
      await _loadUserName();
    }
    return _userName ?? AppConstants.defaultUserName;
  }

  Future<void> updateUserName(String name) async {
    _userName = name;
    await _prefs.setString(AppConstants.keyUserName, name);
  }

  // 設置相關方法
  Future<bool?> getEnableSound() async => _prefs.getBool(AppConstants.keyEnableSound) ?? AppConstants.defaultEnableSound;
  Future<bool?> getEnableVibration() async => _prefs.getBool(AppConstants.keyEnableVibration) ?? AppConstants.defaultEnableVibration;
  Future<bool?> getEnableNotifications() async => _prefs.getBool(AppConstants.keyEnableNotifications) ?? AppConstants.defaultEnableNotifications;
  Future<bool?> getEnableAutoPlay() async => _prefs.getBool(AppConstants.keyEnableAutoPlay) ?? AppConstants.defaultEnableAutoPlay;
  Future<String?> getPreferredVoice() async => _prefs.getString(AppConstants.keyPreferredVoice) ?? AppConstants.defaultVoice;
  Future<String?> getSelectedTheme() async => _prefs.getString(AppConstants.keySelectedTheme) ?? AppConstants.defaultTheme;

  // 學習提醒設置
  Future<void> setLearningReminder(TimeOfDay time, List<int> days) async {
    final reminderData = {
      'time': {'hour': time.hour, 'minute': time.minute},
      'days': days,
    };
    await _prefs.setString(AppConstants.keyLearningReminder, jsonEncode(reminderData));
  }

  // 私有輔助方法
  Future<void> _loadUserName() async {
    _userName = _prefs.getString(AppConstants.keyUserName);
  }

  Future<UserProgress?> _loadUserProgress() async {
    if (kIsWeb) return null;
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/${AppConstants.userProgressFileName}');
      
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final jsonData = jsonDecode(jsonString);
        return UserProgress.fromJson(jsonData);
      }
    } catch (e) {
      debugPrint('載入用戶進度失敗: $e');
    }
    return null;
  }

  Future<void> _saveUserProgress() async {
    if (kIsWeb || _userProgress == null) return;
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/${AppConstants.userProgressFileName}');
      final jsonString = jsonEncode(_userProgress!.toJson());
      await file.writeAsString(jsonString);
    } catch (e) {
      debugPrint('保存用戶進度失敗: $e');
    }
  }

  Future<Map<String, int>> getRecentProgress() async {
    final Map<String, int> progress = {};
    final keys = _prefs.getKeys().where((key) => key.startsWith('progress_'));
    
    for (final key in keys) {
      final bookId = key.replaceFirst('progress_', '');
      progress[bookId] = _prefs.getInt(key) ?? 0;
    }
    
    return progress;
  }

  Future<void> updateProgress(String bookId, int progress) async {
    await _prefs.setInt('progress_$bookId', progress);
  }

  Future<Map<String, int>> getMasteredWordCounts() async {
    final Map<String, int> counts = {};
    final keys = _prefs.getKeys().where((key) => key.startsWith('mastered_'));
    
    for (final key in keys) {
      final bookId = key.replaceFirst('mastered_', '');
      counts[bookId] = _prefs.getInt(key) ?? 0;
    }
    
    return counts;
  }

  Future<void> updateMasteredWordCount(String bookId, int count) async {
    await _prefs.setInt('mastered_$bookId', count);
  }

  Future<Map<String, int>> getGameScores() async {
    final Map<String, int> scores = {};
    final keys = _prefs.getKeys().where((key) => key.startsWith('game_score_'));
    
    for (final key in keys) {
      final gameId = key.replaceFirst('game_score_', '');
      scores[gameId] = _prefs.getInt(key) ?? 0;
    }
    
    return scores;
  }

  Future<void> updateGameScore(String gameId, int score) async {
    final currentScore = await _prefs.getInt('game_score_$gameId') ?? 0;
    if (score > currentScore) {
      await _prefs.setInt('game_score_$gameId', score);
    }
  }
}
