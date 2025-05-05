import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hello/seller/home_page.dart'; // Import Seller Home Page
import 'package:hello/user/home_page.dart';   // Import User Home Page
import 'package:hello/settings/theme_notifier.dart';

import '../settings/support_page.dart';

class MyLogin extends StatefulWidget {
  const MyLogin({super.key});

  @override
  _MyLoginState createState() => _MyLoginState();
}

class _MyLoginState extends State<MyLogin> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> saveUserPreferences(String userId, String themeMode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
    await prefs.setString('theme_mode', themeMode);
    print("Saved user_id: $userId, theme_mode: $themeMode");
  }

  Future<String?> fetchThemePreference(String userId) async {
    try {
      var url = Uri.parse("http://192.168.205.252/flutter_api/get_theme.php");
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": userId}),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data['theme'];
        }
      }
    } catch (e) {
      print("Failed to fetch theme: $e");
    }
    return null;
  }

  Future<void> validateLogin(BuildContext context) async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    // Basic input validation
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Email and password are required"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Set loading state to true
    setState(() {
      _isLoading = true;
    });

    try {
      var url = Uri.parse("http://192.168.205.252/flutter_api/login.php");
      print("Attempting to connect to: $url");

      // Sending the login request
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        // Parse the response
        var data = jsonDecode(response.body);

        // Check the response status
        if (data['status'] == 'success') {
          if (data.containsKey('role')) {
            String role = data['role'];

            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('userId', data['user_id'].toString()); // ✅ Already here

            // 🔽 🔽 🔽 ADD THIS BLOCK RIGHT HERE 🔽 🔽 🔽
            if (!prefs.containsKey('isDarkMode')) {
              String? themePreference = await fetchThemePreference(data['user_id'].toString());

              if (themePreference != null) {
                bool isDark = themePreference == "Dark Mode";
                Provider.of<ThemeNotifier>(context, listen: false).toggleTheme(isDark);
                await prefs.setBool('isDarkMode', isDark); // save it locally
              }
            }
            // 🔼 🔼 🔼 ADD ABOVE 🔼 🔼 🔼

            // Navigate based on the role
            if (role.contains('Customer and Seller')) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => SellerHomePage()),
              );
            } else if (role.contains('Only Rent/Buy the product')) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => UserHomePage()),
              );
            } else {
              // Handle invalid role or role not assigned
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Invalid role or role not assigned"),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } else {
            // Handle missing 'role' in the response
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Role not assigned or missing in the response"),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          // If login fails (status is not 'success')
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Check Your Email OR Password."),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Handle response status other than 200
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${response.statusCode}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Handle any network errors or exceptions
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Network Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Reset loading state
      setState(() {
        _isLoading = false;
      });
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
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            height: screenSize.height,
            padding: EdgeInsets.symmetric(horizontal: padding, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Row(
                  children: [
                    Image.asset(
                      'assets/info3.png',
                      height: 180,
                      width: 180,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Cloth o'clock",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                _buildTextField("Enter Your Email", Icons.email, false, emailController),
                const SizedBox(height: 20),
                _buildPasswordField("Enter Your Password", Icons.lock, passwordController),
                const SizedBox(height: 15),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/forgot_password');
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                GestureDetector(
                  onTap: _isLoading ? null : () => validateLogin(context),
                  child: Container(
                    width: screenSize.width * 0.5,
                    height: 55,
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
                    child: Center(
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(  // Remove const here
                      "Don't have an account? ",
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: const Text(
                        'Register',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                )

              ],
            ),
          ),
        ),
      ),
      // Add the floating action button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SupportPage()), // Navigate to the SupportPage
          );
        },
        child: Icon(Icons.help_outline),
      ),

    );
  }

  // Text field for email
  Widget _buildTextField(String hintText, IconData icon, bool obscureText, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          labelText: hintText,
          prefixIcon: Icon(icon,   color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.blue,),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }

  // Password field with visibility toggle
  Widget _buildPasswordField(String hintText, IconData icon, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        obscureText: !_isPasswordVisible,
        keyboardType: TextInputType.text,
        decoration: InputDecoration(
          labelText: hintText,
          prefixIcon: Icon(icon,   color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.blue,),
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }
}

