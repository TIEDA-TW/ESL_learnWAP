import 'package:flutter/painting.dart'; // Required for Rect

class WordMatchData {
  final List<String> words;
  final List<String> translations;

  WordMatchData({
    required this.words,
    required this.translations,
  });
}

class SentenceFillData {
  final String sentence;
  final List<String> options;

  SentenceFillData({
    required this.sentence,
    required this.options,
  });
}

class PictureDiffData {
  final String originalImage;
  final String modifiedImage;
  final List<Rect> diffAreas; // Defines the clickable areas of differences

  PictureDiffData({
    required this.originalImage,
    required this.modifiedImage,
    required this.diffAreas,
  });

  // Helper to get total number of differences
  int get diffCount => diffAreas.length;
}