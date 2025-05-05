import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hello/login/login.dart';

class ChangePasswordScreen extends StatefulWidget {
  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String? userId;
  bool _isLoading = false;

  bool _showOld = false;
  bool _showNew = false;
  bool _showConfirm = false;

  String _passwordStrength = '';

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _newPasswordController.addListener(_checkPasswordStrength);
  }

  void _checkPasswordStrength() {
    String password = _newPasswordController.text.trim();
    setState(() {
      if (password.length < 6) {
        _passwordStrength = 'Too Short';
      } else if (!RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[@\$!%*?&])').hasMatch(password)) {
        _passwordStrength = 'Weak';
      } else {
        _passwordStrength = 'Strong';
      }
    });
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
    });
  }

  void _changePassword() async {
    if (userId == null) {
      _showMessage("User not logged in", Colors.red);
      return;
    }

    String oldPassword = _oldPasswordController.text.trim();
    String newPassword = _newPasswordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      _showMessage("Please fill all fields", Colors.red);
      return;
    }

    if (newPassword != confirmPassword) {
      _showMessage("New Password and Confirm Password must match", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    var url = Uri.parse("http://192.168.205.252/flutter_api/change_password.php");

    try {
      var response = await http.post(url, body: {
        'user_id': userId,
        'oldPassword': oldPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      });

      // Print the raw response to debug
      print('Server Response: ${response.body}');

      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        if (data['status'] == 'error') {
          _showMessage(data['message'], Colors.red);
        } else if (data['status'] == 'success') {
          _showMessage(data['message'], Colors.green);
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          await Future.delayed(Duration(seconds: 2));
          Navigator.pushAndRemoveUntil(
              context, MaterialPageRoute(builder: (_) => MyLogin()), (route) => false);
        } else {
          _showMessage("Unexpected response format", Colors.red);
        }
      } else {
        _showMessage("Failed to communicate with the server.", Colors.red);
      }
    } catch (e) {
      _showMessage("An error occurred: $e", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? Colors.grey[900] : Colors.white;
    final cardColor = isDarkMode ? Colors.grey[800] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final borderColor = isDarkMode ? Colors.white70 : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Change Password", style: TextStyle(color: textColor)),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(height: 20),
            CircleAvatar(
              radius: 60,
              backgroundColor: cardColor,
              child: Icon(Icons.lock_outline_rounded, size: 80, color: borderColor),
            ),
            SizedBox(height: 20),
            _buildTextField(_oldPasswordController, "Old Password", isDarkMode, _showOld, () => setState(() => _showOld = !_showOld)),
            SizedBox(height: 15),
            _buildTextField(_newPasswordController, "New Password", isDarkMode, _showNew, () => setState(() => _showNew = !_showNew)),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Strength: $_passwordStrength",
                style: TextStyle(
                  color: _passwordStrength == 'Strong' ? Colors.green : _passwordStrength == 'Medium' ? Colors.orange : Colors.red,
                ),
              ),
            ),
            SizedBox(height: 15),
            _buildTextField(_confirmPasswordController, "Confirm Password", isDarkMode, _showConfirm, () => setState(() => _showConfirm = !_showConfirm)),
            SizedBox(height: 40),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              onPressed: _changePassword,
              child: Text("Change Password", style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, bool isDark, bool isVisible, VoidCallback toggleVisibility) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white : Colors.black),
        filled: true,
        fillColor: isDark ? Colors.grey[800] : Colors.white,
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: isDark ? Colors.white : Colors.black),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: isDark ? Colors.white : Colors.black45),
        ),
        suffixIcon: IconButton(
          icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: isDark ? Colors.white : Colors.black54),
          onPressed: toggleVisibility,
        ),
      ),
    );
  }
}
