import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _tts = FlutterTts();

  VoidCallback? _onComplete;

  void setCompletionHandler(VoidCallback? onComplete) {
    _onComplete = onComplete;
    _tts.setCompletionHandler(() {
      if (_onComplete != null) _onComplete!();
    });
  }

  Future<void> speak(String text, {double rate = 1.0, String lang = 'en-US', String? voice}) async {
    await _tts.setLanguage(lang);
    await _tts.setSpeechRate(rate);
    if (voice != null) {
      await _tts.setVoice({'name': voice, 'locale': lang});
    }
    await _tts.speak(text);
  }

  Future<List<dynamic>> getVoices() async => await _tts.getVoices;

  Future<void> stop() async => await _tts.stop();
}
