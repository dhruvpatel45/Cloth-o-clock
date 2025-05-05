import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'otpscreen_email.dart';

class ChangeEmailScreen extends StatefulWidget {
  final String currentEmail;

  ChangeEmailScreen({required this.currentEmail});

  @override
  _ChangeEmailScreenState createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  TextEditingController _emailController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.currentEmail;
  }

  void _navigateToOTP() async {
    String newEmail = _emailController.text.trim();

    if (newEmail.isNotEmpty && newEmail != widget.currentEmail) {
      setState(() {
        isLoading = true;
      });

      final response = await http.post(
        Uri.parse("http://192.168.205.252/flutter_api/email_otp.php"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"email": newEmail}),
      );

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OTPScreenEmail(
                oldEmail: widget.currentEmail,
                newValue: newEmail,
                onVerified: (verifiedEmail) {
                  Navigator.pop(context, verifiedEmail);
                },
              ),
            ),
          );
        } else {
          _showErrorMessage(data['message']);
        }
      } else {
        _showErrorMessage("Failed to send OTP. Please try again.");
      }
    } else {
      _showErrorMessage("Please enter a valid new email.");
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? Colors.grey[800] : Colors.white;
    final iconColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text('Change Email', style: TextStyle(color: textColor)),
      ),
      backgroundColor: bgColor,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 70,
              backgroundColor: cardColor,
              child: Icon(Icons.email_outlined, size: 120, color: iconColor),
            ),
            const SizedBox(height: 30),
            Text(
              "Please provide your new Email Address.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: "New Email",
                labelStyle: TextStyle(color: isDark ? Colors.grey[300] : Colors.black),
                filled: true,
                fillColor: cardColor,
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black45),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: isDark ? Colors.white : Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _navigateToOTP,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text('Send OTP', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
