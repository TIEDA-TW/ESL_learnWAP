import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/login_form_screen.dart';
import '../screens/improved/home_screen.dart';

class AppRoutes {
  // 主路由
  static const String splash = '/splash';
  static const String home = '/';
  static const String login = '/login';
  static const String settings = '/settings';
  static const String changePassword = '/change-password'; // New route
  
  // 學習相關路由
  static const String reading = '/reading';
  static const String following = '/following';
  static const String flashcards = '/flashcards';
  static const String games = '/games';
  
  // 遊戲子路由
  static const String wordMatch = '/games/word-match';
  static const String sentenceFill = '/games/sentence-fill';
  static const String picturePuzzle = '/games/picture-puzzle';
  
  // 其他功能路由
  static const String progress = '/progress';
  static const String profile = '/profile';
  
  // 定義路由映射
  static Map<String, WidgetBuilder> getRoutes(BuildContext context) {
    return {
      splash: (context) => SplashScreen(),
      home: (context) => ImprovedHomeScreen(),
      login: (context) => LoginFormScreen(),
      // 添加其他路由時可以擴展這裡
    };
  }
} 