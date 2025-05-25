import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 添加鍵盤事件支援
import 'package:english_learning_app/config/app_themes.dart';
import 'package:english_learning_app/services/auth_service.dart';
import 'package:english_learning_app/routes/app_routes.dart'; // For named routes

class LoginFormScreen extends StatefulWidget {
  const LoginFormScreen({Key? key}) : super(key: key);

  @override
  _LoginFormScreenState createState() => _LoginFormScreenState();
}

class _LoginFormScreenState extends State<LoginFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService(); // Instantiate AuthService

  // 添加 FocusNode 來控制焦點
  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _loginButtonFocusNode = FocusNode();

  bool _isLoading = false; // To manage loading state
  String? _errorMessage; // To display login errors

  // Example: Allow theme switching for demonstration.
  AppThemeType _currentThemeType = AppThemeType.ocean; // Default theme

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear previous error
    });

    if (_formKey.currentState!.validate()) {
      final username = _usernameController.text;
      final password = _passwordController.text;

      final result = await _authService.signIn(username, password);
      final bool success = result['success'] == 'true'; // 修正類型檢查

      if (mounted) { // Check if the widget is still in the tree
        setState(() {
          _isLoading = false;
        });

        if (success) {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        } else {
          setState(() {
            _errorMessage = result['error'] ?? '使用者名稱或密碼錯誤，請重新輸入。';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData currentTheme = getThemeData(_currentThemeType);

    return Theme(
      data: currentTheme,
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.only(bottom: 40.0),
                    child: Image.asset(
                      'assets/images/ESL Logo.png',
                      height: 120,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.image_not_supported, size: 100, color: Colors.grey);
                      },
                    ),
                  ),
                  Text(
                    '歡迎回來！',
                    textAlign: TextAlign.center,
                    style: currentTheme.textTheme.headlineLarge?.copyWith(fontSize: 26.0),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '請登入以繼續您的學習之旅。',
                    textAlign: TextAlign.center,
                    style: currentTheme.textTheme.bodyMedium?.copyWith(fontSize: 16.0),
                  ),
                  const SizedBox(height: 32),
                  if (_errorMessage != null && !_isLoading) // Show error message if any
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: currentTheme.colorScheme.error, fontSize: 14.0),
                      ),
                    ),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        TextFormField(
                          controller: _usernameController,
                          focusNode: _usernameFocusNode,
                          decoration: InputDecoration(
                            labelText: '使用者名稱',
                            prefixIcon: Icon(Icons.person_outline, color: currentTheme.colorScheme.primary),
                          ),
                          style: currentTheme.textTheme.bodyLarge,
                          textInputAction: TextInputAction.next, // 顯示下一步按鈕
                          onFieldSubmitted: (value) {
                            // 按下 Enter 鍵時跳到密碼欄位
                            FocusScope.of(context).requestFocus(_passwordFocusNode);
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '請輸入您的使用者名稱';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          decoration: InputDecoration(
                            labelText: '密碼',
                            prefixIcon: Icon(Icons.lock_outline, color: currentTheme.colorScheme.primary),
                          ),
                          obscureText: true,
                          style: currentTheme.textTheme.bodyLarge,
                          textInputAction: TextInputAction.done, // 顯示完成按鈕
                          onFieldSubmitted: (value) {
                            // 按下 Enter 鍵時跳到登入按鈕
                            FocusScope.of(context).requestFocus(_loginButtonFocusNode);
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '請輸入您的密碼';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        _isLoading
                            ? Center(child: CircularProgressIndicator(color: currentTheme.colorScheme.primary))
                            : Focus(
                                focusNode: _loginButtonFocusNode,
                                onKeyEvent: (node, event) {
                                  // 處理登入按鈕的 Enter 鍵事件
                                  if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
                                    _login();
                                    return KeyEventResult.handled;
                                  }
                                  return KeyEventResult.ignored;
                                },
                                child: ElevatedButton(
                                  onPressed: _login,
                                  child: const Text('登入'),
                                ),
                              ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 30.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text('主題：', style: currentTheme.textTheme.bodyMedium),
                        DropdownButton<AppThemeType>(
                          value: _currentThemeType,
                          icon: Icon(Icons.color_lens, color: currentTheme.colorScheme.primary),
                          dropdownColor: currentTheme.colorScheme.surface,
                          style: currentTheme.textTheme.bodyMedium,
                          items: AppThemeType.values.map((AppThemeType type) {
                            // 主題名稱中文化
                            String getThemeName(AppThemeType type) {
                              switch (type) {
                                case AppThemeType.ocean:
                                  return '海洋';
                                case AppThemeType.forest:
                                  return '森林';
                                case AppThemeType.fantasy:
                                  return '夢幻';
                              }
                            }
                            
                            return DropdownMenuItem<AppThemeType>(
                              value: type,
                              child: Text(
                                getThemeName(type),
                                style: TextStyle(color: currentTheme.textTheme.bodyMedium?.color),
                              ),
                            );
                          }).toList(),
                          onChanged: (AppThemeType? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _currentThemeType = newValue;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    _loginButtonFocusNode.dispose();
    super.dispose();
  }
} 