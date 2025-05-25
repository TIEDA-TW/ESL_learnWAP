import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert'; // For utf8
import 'package:crypto/crypto.dart'; // For sha256

class AuthService {
  static const String _loggedInKey = 'isLoggedIn';
  static const String _usernameKey = 'username';
  static const String _passwordHashKey = 'passwordHash'; // Key to store password hash

  // Default credentials for the first run or if not set
  static const String _defaultUsername = 'admin';
  // SHA256 hash of "admin". You can generate this: print(_hashPassword('admin'));
  static const String _defaultPasswordHash = '8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918';

  // Login attempt limits
  static const int maxLoginAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 5);
  static const String _loginAttemptsPrefix = 'loginAttempts_';
  static const String _lockoutTimestampPrefix = 'lockoutTimestamp_';

  // Method to hash password
  String _hashPassword(String password) {
    final bytes = utf8.encode(password); // Encode password to UTF-8
    final digest = sha256.convert(bytes); // Hash it
    return digest.toString(); // Return hex string
  }

  // Initialize default admin credentials if they don't exist
  Future<void> _initializeDefaultCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_passwordHashKey)) {
      await prefs.setString(_passwordHashKey, _defaultPasswordHash);
      // For simplicity, we'll assume the default username is always 'admin'
      // and doesn't need to be explicitly stored if only one user is supported this way.
      // If multiple users were supported with this simple SharedPreferences setup,
      // you'd need a way to associate usernames with their password hashes.
    }
  }

  Future<Map<String, String>> signIn(String username, String password) async {
    await _initializeDefaultCredentials(); // Ensure default credentials are set if needed
    final prefs = await SharedPreferences.getInstance();

    // Check for lockout
    final lockoutKey = _lockoutTimestampPrefix + username;
    final lockoutTimestamp = prefs.getInt(lockoutKey);
    if (lockoutTimestamp != null) {
      final lockoutEndTime = DateTime.fromMillisecondsSinceEpoch(lockoutTimestamp).add(lockoutDuration);
      if (DateTime.now().isBefore(lockoutEndTime)) {
        final remainingLockout = lockoutEndTime.difference(DateTime.now());
        return {'success': 'false', 'error': 'Account locked. Try again in ${remainingLockout.inMinutes + 1} minutes.'};
      } else {
        // Lockout expired, remove old lockout info
        await prefs.remove(lockoutKey);
        await prefs.remove(_loginAttemptsPrefix + username);
      }
    }
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    final String currentPasswordHash = prefs.getString(_passwordHashKey) ?? _defaultPasswordHash;
    final String inputPasswordHash = _hashPassword(password);

    // For now, we only validate against the 'admin' user and the stored/default hash.
    if (username == _defaultUsername && inputPasswordHash == currentPasswordHash) {
      await prefs.setBool(_loggedInKey, true);
      await prefs.setString(_usernameKey, username);
      // Reset login attempts on successful login
      await prefs.remove(_loginAttemptsPrefix + username);
      await prefs.remove(lockoutKey); // Ensure any expired lockout is also cleared
      return {'success': 'true'};
    } else {
      // Handle login attempts
      final attemptsKey = _loginAttemptsPrefix + username;
      int attempts = (prefs.getInt(attemptsKey) ?? 0) + 1;
      await prefs.setInt(attemptsKey, attempts);

      if (attempts >= maxLoginAttempts) {
        await prefs.setInt(lockoutKey, DateTime.now().millisecondsSinceEpoch);
        return {'success': 'false', 'error': 'Account locked due to too many failed attempts. Try again in ${lockoutDuration.inMinutes} minutes.'};
      }
      return {'success': 'false', 'error': 'Invalid username or password.'};
    }
  }

  Future<bool> changePassword(String username, String oldPassword, String newPassword) async {
    // For this simple implementation, we assume 'username' is always 'admin'
    // and we are changing the password for this single admin user.
    if (username != _defaultUsername) {
      return false; // Or handle error for unknown user
    }

    final prefs = await SharedPreferences.getInstance();
    final storedPasswordHash = prefs.getString(_passwordHashKey) ?? _defaultPasswordHash;
    final oldPasswordHash = _hashPassword(oldPassword);

    if (oldPasswordHash == storedPasswordHash) {
      final newPasswordHash = _hashPassword(newPassword);
      await prefs.setString(_passwordHashKey, newPasswordHash);
      // Password changed, reset login attempts and lockout for this user
      await prefs.remove(_loginAttemptsPrefix + username);
      await prefs.remove(_lockoutTimestampPrefix + username);
      return true;
    }
    return false; // Old password did not match
  }


  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedInKey);
    await prefs.remove(_usernameKey); // Typically, you might want to keep username for pre-filling login form
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loggedInKey) ?? false;
  }

  Future<String?> getLoggedInUsername() async {
    final prefs = await SharedPreferences.getInstance();
    // Return the stored username if logged in, otherwise null
    if (await isLoggedIn()) {
      return prefs.getString(_usernameKey);
    }
    return null;
  }
}
