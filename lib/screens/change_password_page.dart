import 'package:flutter/material.dart';
import 'package:english_learning_app/services/auth_service.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({Key? key}) : super(key: key);

  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  Future<void> _changePassword() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    if (_formKey.currentState!.validate()) {
      final username = await _authService.getLoggedInUsername();
      if (username == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error: User not logged in.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!), backgroundColor: Colors.red),
        );
        return;
      }

      final success = await _authService.changePassword(
        username,
        _oldPasswordController.text,
        _newPasswordController.text,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (success) {
          _successMessage = 'Password changed successfully!';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_successMessage!), backgroundColor: Colors.green),
          );
          _formKey.currentState?.reset();
          _oldPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
          // Optionally navigate back after a delay
          // Future.delayed(Duration(seconds: 2), () {
          //   if (mounted && Navigator.canPop(context)) {
          //     Navigator.pop(context);
          //   }
          // });
        } else {
          _errorMessage = 'Failed to change password. Old password might be incorrect.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_errorMessage!), backgroundColor: Colors.red),
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

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'New password cannot be empty.';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long.';
    }
    // TODO: Add more complexity requirements if desired (e.g., uppercase, number, symbol)
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Access theme for consistent styling

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _oldPasswordController,
                decoration: InputDecoration(
                  labelText: 'Old Password',
                  prefixIcon: Icon(Icons.lock_open_outlined, color: theme.colorScheme.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your old password.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _newPasswordController,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: Icon(Icons.lock_outline, color: theme.colorScheme.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                obscureText: true,
                validator: _validateNewPassword,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: Icon(Icons.lock_outline, color: theme.colorScheme.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your new password.';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
              else
                ElevatedButton(
                  onPressed: _changePassword,
                  style: ElevatedButton.styleFrom(
                    // backgroundColor: theme.colorScheme.primary, // Handled by theme
                    // foregroundColor: theme.colorScheme.onPrimary, // Handled by theme
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Change Password'),
                ),
              // if (_errorMessage != null) ...[
              //   const SizedBox(height: 16),
              //   Text(
              //     _errorMessage!,
              //     textAlign: TextAlign.center,
              //     style: TextStyle(color: theme.colorScheme.error, fontSize: 14),
              //   ),
              // ],
              // if (_successMessage != null) ...[
              //   const SizedBox(height: 16),
              //   Text(
              //     _successMessage!,
              //     textAlign: TextAlign.center,
              //     style: TextStyle(color: Colors.green[700], fontSize: 14, fontWeight: FontWeight.bold),
              //   ),
              // ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
