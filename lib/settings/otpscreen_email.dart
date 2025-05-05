import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OTPScreenEmail extends StatefulWidget {
  final String oldEmail;
  final String newValue; // New email
  final Function(String) onVerified;

  OTPScreenEmail({required this.oldEmail, required this.newValue, required this.onVerified});

  @override
  _OTPScreenEmailState createState() => _OTPScreenEmailState();
}

class _OTPScreenEmailState extends State<OTPScreenEmail> {
  List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  // ✅ Verify OTP and Update Email
  void _verifyOTP() async {
    String otp = _otpControllers.map((controller) => controller.text).join();

    if (otp.length == 6) {
      try {
        final response = await http.post(
          Uri.parse("http://192.168.205.252/flutter_api/update_email.php"),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "old_email": widget.oldEmail,
            "new_email": widget.newValue,
            "otp": otp,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == 'success') {
            widget.onVerified(widget.newValue); // ✅ Send updated email back
            Navigator.pop(context); // ✅ Close OTP screen and go back
          } else {
            _showErrorMessage(data['message']);
          }
        } else {
          _showErrorMessage("Failed to verify OTP.");
        }
      } catch (e) {
        _showErrorMessage("An error occurred. Please try again.");
      }
    } else {
      _showErrorMessage("Enter a valid 6-digit OTP.");
    }
  }

  // ✅ Show Error Message using SnackBar
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.white, title: const Text('Enter OTP')),
      body: Container(
        color: Colors.white,
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 70),
            const Text(
              "Verification",
              style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 100),
            const Text(
              "Verification code has been sent to\n your updated Email address",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 35),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                return Container(
                  width: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  child: TextField(
                    controller: _otpControllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      counterText: "",
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                      }
                      if (value.isEmpty && index > 0) {
                        FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
                      }
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _verifyOTP,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text('Verify OTP', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
