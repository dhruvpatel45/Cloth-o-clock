import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

class ForgotPassword2 extends StatefulWidget {
  final String email;

  const ForgotPassword2({super.key, required this.email});

  @override
  _ForgotPassword2State createState() => _ForgotPassword2State();
}

class _ForgotPassword2State extends State<ForgotPassword2> {
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  Future<void> updatePassword() async {
    if (newPasswordController.text.isEmpty || confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields are required")),
      );
      return;
    }

    if (newPasswordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    final url = Uri.parse('http://192.168.205.252/flutter_api/update_password.php');
    final Map<String, dynamic> requestBody = {
      "email": widget.email,
      "new_password": newPasswordController.text,
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password updated successfully!")),
        );
        Navigator.pushNamed(context, '/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${data['message']}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Network Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final padding = screenSize.width * 0.06;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        width: double.infinity,
        height: double.infinity,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: padding, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const SizedBox(height: 290),

              // New Password Field
              _buildTextField(
                controller: newPasswordController,
                hintText: 'Enter New Password',
                icon: Icons.lock,
                obscureText: true,
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 15),

              // Confirm Password Field
              _buildTextField(
                controller: confirmPasswordController,
                hintText: 'Confirm New Password',
                icon: Icons.lock_outline,
                obscureText: true,
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 20),

              // Confirm Button
              GestureDetector(
                onTap: updatePassword,
                child: Container(
                  width: screenSize.width * 0.5,
                  height: 45,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF1E88E5),
                        Color(0xFF64B5F6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        offset: const Offset(0, 5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'CONFIRM PASSWORD',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required bool obscureText,
    required bool isDarkMode,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white : Colors.black),
      decoration: InputDecoration(
        filled: true,
        fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
        hintText: hintText,
        hintStyle: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.black54),
        prefixIcon: Icon(icon, color: isDarkMode ? Colors.white : Colors.blue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      ),
    );
  }
}
