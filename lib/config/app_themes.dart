import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppThemes {
  // 兒童友善的海洋主題 - 使用更明亮活潑的顏色
  static final ThemeData oceanTheme = ThemeData(
    primaryColor: Colors.blue[600],
    colorScheme: ColorScheme.light(
      primary: Colors.blue[600]!,
      secondary: Colors.amber[500]!,  // 更鮮豔的橙黃色
      background: const Color(0xFFF0F8FF),  // 淡藍色背景
      surface: Colors.white,
      error: Colors.red[400]!,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onBackground: Colors.black,
      onSurface: Colors.black,
      onError: Colors.white,
    ),
    fontFamily: 'Noto Sans TC',
    textTheme: _buildTextTheme(baseColor: Colors.blue[700]!),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.blue[400],
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: _buildElevatedButtonTheme(Colors.orange[300]!),
    cardTheme: _buildCardTheme(shadowColor: Colors.blue[200]!),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: Colors.orange[300],
      unselectedItemColor: Colors.blue[200],
      type: BottomNavigationBarType.fixed,
    ),
    inputDecorationTheme: _buildInputDecorationTheme(borderColor: Colors.blue[400]!),
    useMaterial3: true,
  );

  // 兒童友善的森林主題 - 自然清新的顏色
  static final ThemeData forestTheme = ThemeData(
    primaryColor: Colors.green[600],
    colorScheme: ColorScheme.light(
      primary: Colors.green[600]!,
      secondary: Colors.lime[400]!,  // 更活潑的黃綠色
      background: const Color(0xFFF5FFF5),  // 淡綠色背景
      surface: Colors.white,
      error: Colors.red[400]!,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onBackground: Colors.black,
      onSurface: Colors.black,
      onError: Colors.white,
    ),
    fontFamily: 'Noto Sans TC',
    textTheme: _buildTextTheme(baseColor: Colors.green[700]!),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.green[400],
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: _buildElevatedButtonTheme(Colors.yellow[300]!),
    cardTheme: _buildCardTheme(shadowColor: Colors.green[200]!),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: Colors.yellow[300],
      unselectedItemColor: Colors.green[200],
      type: BottomNavigationBarType.fixed,
    ),
    inputDecorationTheme: _buildInputDecorationTheme(borderColor: Colors.green[400]!),
    useMaterial3: true,
  );

  // 兒童友善的夢幻主題 - 粉嫩夢幻的顏色
  static final ThemeData fantasyTheme = ThemeData(
    primaryColor: Colors.purple[400],
    colorScheme: ColorScheme.light(
      primary: Colors.purple[400]!,
      secondary: Colors.pink[300]!,  // 更鮮明的粉色
      background: const Color(0xFFFFF5FF),  // 淡紫色背景
      surface: Colors.white,
      error: Colors.red[400]!,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onBackground: Colors.black,
      onSurface: Colors.black,
      onError: Colors.white,
    ),
    fontFamily: 'Noto Sans TC',
    textTheme: _buildTextTheme(baseColor: Colors.purple[700]!),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.purple[300],
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: _buildElevatedButtonTheme(Colors.pink[200]!),
    cardTheme: _buildCardTheme(shadowColor: Colors.purple[100]!),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: Colors.pink[200],
      unselectedItemColor: Colors.purple[100],
      type: BottomNavigationBarType.fixed,
    ),
    inputDecorationTheme: _buildInputDecorationTheme(borderColor: Colors.purple[300]!),
    useMaterial3: true,
  );

  static TextTheme _buildTextTheme({required Color baseColor}) {
    return TextTheme(
      // 針對兒童調整字體大小，使其更易讀
      headlineLarge: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold, color: baseColor, letterSpacing: 1.2),
      headlineMedium: TextStyle(fontSize: 26.0, fontWeight: FontWeight.bold, color: baseColor.withOpacity(0.9)),
      headlineSmall: TextStyle(fontSize: 22.0, fontWeight: FontWeight.w600, color: baseColor.withOpacity(0.85)),
      bodyLarge: TextStyle(fontSize: 20.0, color: Colors.black87, height: 1.5),  // 增加行高
      bodyMedium: TextStyle(fontSize: 18.0, color: Colors.black54, height: 1.4),
      labelLarge: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.white), // 按鈕文字更大
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme(Color buttonColor) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 56), // 更高的按鈕，適合兒童點擊
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0), // 更圓潤的邊角
        ),
        elevation: 4, // 添加陰影效果
        textStyle: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, fontFamily: 'Noto Sans TC'),
      ).copyWith(
        // 添加按壓效果
        overlayColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.pressed)) {
              return Colors.white.withOpacity(0.3);
            }
            return null;
          },
        ),
      ),
    );
  }

  static CardTheme _buildCardTheme({required Color shadowColor}) {
    return CardTheme(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24), // 更圓潤的卡片
        side: BorderSide(
          color: shadowColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      elevation: 6, // 更明顯的陰影
      color: Colors.white,
      shadowColor: shadowColor.withOpacity(0.3),
      margin: const EdgeInsets.all(12.0),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme({required Color borderColor}) {
    return InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0), // 更圓潤
        borderSide: BorderSide(color: borderColor, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide(color: borderColor.withOpacity(0.5), width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide(color: borderColor, width: 3.0),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0), // 更大的內邊距
      labelStyle: TextStyle(fontSize: 18.0), // 更大的標籤文字
      hintStyle: TextStyle(fontSize: 16.0, color: Colors.grey[400]),
    );
  }

  // You can add a default dark theme as well if needed
  static final ThemeData defaultDarkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    cardTheme: CardTheme(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
    ),
  );
}

// Enum to represent the available themes
enum AppThemeType {
  ocean,
  forest,
  fantasy,
  // Add more themes here if needed
}

// Helper to get ThemeData from AppThemeType
ThemeData getThemeData(AppThemeType themeType) {
  switch (themeType) {
    case AppThemeType.ocean:
      return AppThemes.oceanTheme;
    case AppThemeType.forest:
      return AppThemes.forestTheme;
    case AppThemeType.fantasy:
      return AppThemes.fantasyTheme;
    default:
      return AppThemes.oceanTheme; // Default theme
  }
}

// 使用 Google Fonts 獲取 Noto Sans TC 字體
TextTheme _getBaseTextTheme() {
  return GoogleFonts.notoSansTextTheme(
    const TextTheme(
      // 原有的字體樣式定義
    ),
  );
}
