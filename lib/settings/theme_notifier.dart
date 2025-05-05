import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ThemeNotifier extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeNotifier(bool initialMode) {
    _isDarkMode = initialMode;
  }

  void toggleTheme(bool value) async {
    _isDarkMode = value;
    notifyListeners();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);

    // ✅ Now also update in DB
    String? userId = prefs.getString('userId');
    if (userId != null && userId.isNotEmpty) {
      await _updateThemeInDB(userId, value);
    }
  }

  Future<void> _updateThemeInDB(String userId, bool isDark) async {
    print("🔁 Sending to DB: id = $userId, theme = ${isDark
        ? "Dark Mode"
        : "Light Mode"}"); // ✅ Add here

    try {
      final response = await http.post(
        Uri.parse("http://192.168.205.252/flutter_api/update_theme_preference.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id": userId, // ✅ OR "user_id" depending on your PHP file
          "theme": isDark ? "Dark Mode" : "Light Mode",
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          print("✅ Theme saved to DB");
        } else {
          print("❌ DB Error: ${data['message']}");
        }
      } else {
        print("❌ HTTP Error: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Exception: $e");
    }
  }
}