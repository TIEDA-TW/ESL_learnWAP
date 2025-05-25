import 'package:flutter/foundation.dart';
import 'dart:js' as js;

/// 使用 Web Speech API 朗讀文字（僅限Web平台）
/// [rate] 建議值 0.7、1.0、1.3、1.6
void speakWithWebSpeech(String text, {String lang = 'en-US', double rate = 1.0}) {
  if (kIsWeb) {
    js.context.callMethod('eval', ["""
      (function() {
        var utter = new window.SpeechSynthesisUtterance("$text");
        utter.lang = "$lang";
        utter.rate = $rate;
        window.speechSynthesis.speak(utter);
      })();
    """]);
  }
}