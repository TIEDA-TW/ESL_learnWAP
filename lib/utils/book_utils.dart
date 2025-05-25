import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:flutter/services.dart';

/// 自動取得 assets/Book_data 下所有教材（bookId）
Future<List<String>> getAllBookIds() async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final keys = manifest.listAssets();
  final bookIds = <String>{};
  for (final key in keys) {
    final match = RegExp(r'assets/Book_data/(.+)_book_data.json').firstMatch(key);
    if (match != null) {
      bookIds.add(match.group(1)!);
    }
  }
  return bookIds.toList();
}
