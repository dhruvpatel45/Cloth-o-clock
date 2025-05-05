import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../settings/support_page.dart';
import 'login.dart';

class MyRegister extends StatefulWidget {
  const MyRegister({super.key});

  @override
  _MyRegisterState createState() => _MyRegisterState();
}

class _MyRegisterState extends State<MyRegister> {
  String? _selectedRole = "Only Rent/Buy the product";

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  void registerUser() async {
    String name = _fullNameController.text.trim();
    String phone = _contactNumberController.text.trim();
    String email = _emailController.text.trim();
    String pass = _passwordController.text;
    String confirm = _confirmPasswordController.text;

    // Manual Validation
    if (name.isEmpty ||
        phone.isEmpty ||
        email.isEmpty ||
        pass.isEmpty ||
        confirm.isEmpty) {
      _showSnackBar("Please fill in all fields");
      return;
    }

    if (phone.length != 10 || !RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
      _showSnackBar("Enter a valid 10-digit contact number");
      return;
    }

    if (!email.contains("@") || !email.contains(".")) {
      _showSnackBar("Enter a valid email address");
      return;
    }

    if (pass.length < 6) {
      _showSnackBar("Password must be at least 6 characters");
      return;
    }

    if (pass != confirm) {
      _showSnackBar("Passwords do not match");
      return;
    }

    final url = Uri.parse('http://192.168.205.252/flutter_api/register.php');

    final Map<String, dynamic> requestBody = {
      'full_name': name,
      'contact_number': phone,
      'email': email,
      'password': pass,
      'role': _selectedRole ?? '',
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('id', responseData['id'].toString());

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MyLogin()),
        );
      } else {
        _showSnackBar(responseData['message'] ?? "Registration failed");
      }
    } catch (e) {
      _showSnackBar("Network error: $e");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        color: isDarkMode ? Colors.grey[900] : Colors.white,        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Column(
            children: [
              // Logo & App Name
              Row(
                children: [
                  Image.asset('assets/info3.png', height: 180, width: 180),
                  const SizedBox(width: 10),
                  const Text('Cloth o\'clock',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                ],
              ),
              const SizedBox(height: 20),

              _buildTextField("Full Name", Icons.person, _fullNameController, TextInputType.text),
              _buildPhoneField(),
              _buildTextField("Email", Icons.email, _emailController, TextInputType.emailAddress),
              _buildPasswordField("Password", _passwordController, isConfirm: false),
              _buildPasswordField("Confirm Password", _confirmPasswordController, isConfirm: true),
              _buildDropdown(),

              const SizedBox(height: 20),
              _buildSignupButton(),

              const SizedBox(height: 80),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => MyLogin()),
                      );
                    },
                    child: const Text('Login',
                        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => SupportPage()));
        },
        child: Icon(Icons.help_outline),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, TextInputType type) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: _contactNumberController,
        keyboardType: TextInputType.phone,
        maxLength: 10,
        decoration: InputDecoration(
          labelText: "Contact Number",
          prefixIcon: Icon(Icons.phone),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller, {required bool isConfirm}) {
    bool isVisible = isConfirm ? _isConfirmPasswordVisible : _isPasswordVisible;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        obscureText: !isVisible,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.lock),
          suffixIcon: IconButton(
            icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                if (isConfirm) {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                } else {
                  _isPasswordVisible = !_isPasswordVisible;
                }
              });
            },
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: DropdownButtonFormField<String>(
        value: _selectedRole,
        items: const [
          DropdownMenuItem(value: 'Only Rent/Buy the product', child: Text('Only Rent/Buy the product')),
          DropdownMenuItem(value: 'Customer and Seller both', child: Text('Customer and Seller both')),
        ],
        onChanged: (value) => setState(() => _selectedRole = value),
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
    );
  }

  Widget _buildSignupButton() {
    final screenSize = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: registerUser,
      child: Container(
        width: screenSize.width * 0.5,
        height: 55,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E88E5), Color(0xFF64B5F6)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
        ),
        child: const Center(
          child: Text("Signup",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }
}
