// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/auth_service.dart'; // Import AuthService
import 'services/improved/tts_service.dart';
import 'services/env_service.dart';
import 'services/storage_service.dart';
import 'dart:async';
import 'config/app_themes.dart';
import 'routes/app_routes.dart'; // Import AppRoutes
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:js' as js;


// Global instance of AuthService for simplicity in this step.
// In a larger app, consider using a Provider or get_it for dependency injection.
final AuthService authService = AuthService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment variables
  try {
    await dotenv.load(fileName: '.env');
    print('main.dart: Successfully loaded .env file');
  } catch (e) {
    if (kIsWeb) {
      print('無法載入 .env 檔案: $e，將使用預設值');
      print('在 Web 環境中，嘗試使用 window.flutterEnvironment');
      try {
        // 在 Web 環境中，嘗試從 window 對象獲取環境變數
        if (js.context.hasProperty('flutterEnvironment')) {
          final env = js.context['flutterEnvironment'];
          for (var key in js.context['Object'].callMethod('keys', [env])) {
            dotenv.env[key] = env[key];
          }
          print('從 window.flutterEnvironment 成功載入環境變數');
        }
      } catch (jsError) {
        print('JS 環境變數處理錯誤（忽略）: $jsError');
      }
    } else {
      print('main.dart: Could not load .env file: $e, using default values');
    }
  }

  await EnvService().initialize();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Preload all book resources
  await preloadBookResources();

  // Warm up TTS to avoid issues with the first playback
  await warmUpTts();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('Application Error: ${details.exception}');
  };

  // 修改初始路由：總是從啟動動畫開始
  const String initialRoute = AppRoutes.splash;

  runApp(ThemedApp(initialRoute: initialRoute));
}

class ThemedApp extends StatefulWidget {
  final String initialRoute;
  const ThemedApp({Key? key, required this.initialRoute}) : super(key: key);

  @override
  _ThemedAppState createState() => _ThemedAppState();
}

class _ThemedAppState extends State<ThemedApp> {
  AppThemeType _currentThemeType = AppThemeType.ocean; // Default theme

  void _changeTheme(AppThemeType themeType) {
    setState(() {
      _currentThemeType = themeType;
    });
  }

  @override
  Widget build(BuildContext context) {
    final envService = EnvService();
    ThemeData currentTheme = getThemeData(_currentThemeType);

    return MaterialApp(
      title: envService.appName,
      theme: currentTheme,
      darkTheme: AppThemes.defaultDarkTheme,
      themeMode: ThemeMode.system,
      
      initialRoute: widget.initialRoute,
      routes: AppRoutes.getRoutes(context),

      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // This builder can be used for global adjustments or theme switching UI if needed.
        // For now, the theme switching is within LoginFormScreen.
        // If a global theme switcher is needed, it could be placed here.
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus(); // Close keyboard on tap outside
          },
          child: child,
        );
      },
    );
  }
}

// Preload all book resources
Future<void> preloadBookResources() async {
  print('Starting to preload book resources...');
  try {
    if (kIsWeb) {
      try {
        print('Preloading resources in Web environment');
        if (js.context.hasProperty('ensureBookAssetsLoaded')) {
          print('JS preload function found, attempting to call');
          js.context.callMethod('ensureBookAssetsLoaded');
          print('JS resource preload call completed');
        } else {
          print('JS preload function not available, skipping');
        }
      } catch (jsError) {
        print('JS interop error (ignored): $jsError');
      }
      print('Web resource preloading flow completed');
    } else {
      // Preloading for non-Web environments
      final storageService = StorageService();
      final bookIds = await storageService.getHardcodedBookIds();
      print('Preloading ${bookIds.length} book resources');
      for (final bookId in bookIds) {
        final dataPath = 'assets/Book_data/${bookId}_book_data.json';
        try {
          await rootBundle.loadString(dataPath);
          print('Successfully preloaded data: $dataPath');
        } catch (e) {
          print('Failed to preload data: $dataPath - $e');
        }
        final coverPath = 'assets/Books/$bookId/${bookId}_00-00.jpg';
        try {
          await rootBundle.load(coverPath);
          print('Successfully preloaded cover: $coverPath');
        } catch (e) {
          print('Failed to preload cover: $coverPath - $e');
        }
      }
    }
  } catch (e) {
    print('Error during resource preloading (does not affect app startup): $e');
  }
  print('Book resource preloading finished');
}

// TTS warm-up method
Future<void> warmUpTts() async {
  try {
    await TtsService().speak('.', rate: 1.0, lang: 'en-US'); // Warm up with an inconspicuous character
    await Future.delayed(const Duration(milliseconds: 200));
    await TtsService().stop();
  } catch (e) {
    print('TTS warm-up failed: $e');
  }
}

// Original ImprovedApp class (commented out as ThemedApp is now the main app widget)
// class ImprovedApp extends StatelessWidget {
//   const ImprovedApp({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final envService = EnvService();
    
//     return MaterialApp(
//       title: envService.appName,
//       theme: ThemeData( // This is the original theme
//         primaryColor: Color(0xFF43A047), // 綠色
//         fontFamily: 'Noto Sans TC',
//         useMaterial3: true,
//         colorScheme: ColorScheme(
//           primary: Color(0xFF43A047), // 綠色
//           secondary: Color(0xFF1E88E5), // 藍色
//           surface: Colors.white,
//           background: Color(0xFFF3FBFF), // 淡藍背景
//           error: Color(0xFFE53935), // 紅色
//           onPrimary: Colors.white,
//           onSecondary: Colors.white,
//           onSurface: Colors.black,
//           onBackground: Colors.black,
//           onError: Colors.white,
//           brightness: Brightness.light,
//         ),
//         textTheme: const TextTheme(
//           headlineLarge: TextStyle(
//             fontSize: 28.0,
//             fontWeight: FontWeight.bold,
//             color: Color(0xFF43A047),
//           ),
//           headlineMedium: TextStyle(
//             fontSize: 24.0,
//             fontWeight: FontWeight.bold,
//             color: Color(0xFF1E88E5),
//           ),
//           bodyLarge: TextStyle(fontSize: 18.0),
//           bodyMedium: TextStyle(fontSize: 16.0),
//         ),
//         appBarTheme: const AppBarTheme(
//           elevation: 0,
//           centerTitle: true,
//           backgroundColor: Color(0xFF43A047),
//           foregroundColor: Colors.white,
//         ),
//         elevatedButtonTheme: ElevatedButtonThemeData(
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Color(0xFF1E88E5),
//             foregroundColor: Colors.white,
//             padding: const EdgeInsets.symmetric(
//               horizontal: 24,
//               vertical: 12,
//             ),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(16),
//             ),
//           ),
//         ),
//         cardTheme: CardTheme(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//           elevation: 4,
//           color: Colors.white,
//           shadowColor: Color(0xFF0D3559).withOpacity(0.08),
//         ),
//         bottomNavigationBarTheme: const BottomNavigationBarThemeData(
//           selectedItemColor: Color(0xFFFBC02D), // 黃色
//           unselectedItemColor: Colors.grey,
//           type: BottomNavigationBarType.fixed,
//         ),
//       ),
//       darkTheme: ThemeData( // Original dark theme
//         brightness: Brightness.dark,
//         primarySwatch: Colors.blue,
//         useMaterial3: true,
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: Colors.blue,
//           brightness: Brightness.dark,
//         ),
//         cardTheme: CardTheme(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           elevation: 2,
//         ),
//         bottomNavigationBarTheme: const BottomNavigationBarThemeData(
//           selectedItemColor: Colors.blue,
//           unselectedItemColor: Colors.grey,
//           type: BottomNavigationBarType.fixed,
//         ),
//       ),
//       themeMode: ThemeMode.system,
//       home: LoginScreen(), // Original home
//       debugShowCheckedModeBanner: false,
//       builder: (context, child) {
//         return GestureDetector(
//           onTap: () {
//             FocusScope.of(context).unfocus();
//           },
//           child: child,
//         );
//       },
//     );
//   }
// }