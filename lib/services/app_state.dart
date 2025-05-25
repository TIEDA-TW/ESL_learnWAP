import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/loading_state.dart';

class AppState extends ChangeNotifier {
  String _currentCategory = AppConfig.categories[0];
  int _currentPageIndex = 0;
  bool _isReadingEnabled = false;
  double _imageScale = 1.0;
  Size? _imageSize;
  bool _isLoading = true;
  String? _errorMessage;
  LoadingStatus _loadingStatus = LoadingStatus.initial();

  String get currentCategory => _currentCategory;
  int get currentPageIndex => _currentPageIndex;
  bool get isReadingEnabled => _isReadingEnabled;
  double get imageScale => _imageScale;
  Size? get imageSize => _imageSize;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  LoadingStatus get loadingStatus => _loadingStatus;

  void setCategory(String category) {
    _currentCategory = category;
    notifyListeners();
  }

  void setPageIndex(int index) {
    _currentPageIndex = index;
    notifyListeners();
  }

  void setReadingEnabled(bool enabled) {
    _isReadingEnabled = enabled;
    notifyListeners();
  }

  void setImageScale(double scale) {
    _imageScale = scale;
    notifyListeners();
  }

  void setImageSize(Size size) {
    _imageSize = size;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void setLoadingStatus(LoadingStatus status) {
    _loadingStatus = status;
    notifyListeners();
  }

  void updateLoadingProgress(double progress, String message) {
    _loadingStatus = LoadingStatus(progress: progress, message: message);
    notifyListeners();
  }

  void nextPage() {
    _currentPageIndex++;
    notifyListeners();
  }

  void previousPage() {
    _currentPageIndex--;
    notifyListeners();
  }
}