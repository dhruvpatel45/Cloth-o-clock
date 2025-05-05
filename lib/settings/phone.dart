import 'package:flutter/material.dart';
import 'otpscreen_phone.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChangePhoneScreen extends StatefulWidget {
  final String currentPhone;

  ChangePhoneScreen({required this.currentPhone});

  @override
  _ChangePhoneScreenState createState() => _ChangePhoneScreenState();
}

class _ChangePhoneScreenState extends State<ChangePhoneScreen> {
  TextEditingController _phoneController = TextEditingController();
  String? userId;
  bool _isLoading = false; // ✅ Add loading state

  @override
  void initState() {
    super.initState();
    _phoneController.text = widget.currentPhone;
    _fetchUserDetails(); // ✅ Fetch userId on screen load
  }

  Future<void> _fetchUserDetails() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      userId = prefs.getString('userId');
      if (userId == null) {
        _showErrorMessage('User not logged in.');
        return;
      }
    } catch (e) {
      _showErrorMessage('An unexpected error occurred. Please try again.');
    }
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _sendOTP(String newPhone) async {
    if (userId == null) {
      await _fetchUserDetails(); // ✅ Ensure userId is fetched before sending OTP
    }

    if (userId == null) {
      _showErrorMessage("User ID not available. Please log in again.");
      return;
    }

    setState(() {
      _isLoading = true; // ✅ Show loading animation
    });

    print("Sending OTP to: $newPhone for user ID: $userId"); // ✅ Debug

    final url = "http://192.168.205.252/flutter_api/phone_otp.php";

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'new_phone': newPhone,
      }),
    );

    final data = jsonDecode(response.body);

    setState(() {
      _isLoading = false; // ✅ Hide loading animation after response
    });

    if (data['status'] == 'success') {
      print("OTP sent successfully to $newPhone"); // ✅ Debug
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OTPScreenPhone(
            newValue: newPhone,
            onVerified: (verifiedPhone) {
              Navigator.pop(context, verifiedPhone);
            },
          ),
        ),
      );
    } else {
      _showErrorMessage(data['message']);
    }
  }

  void _navigateToOTP() {
    String newPhone = _phoneController.text.trim();
    if (newPhone.length == 10 && newPhone != widget.currentPhone) {
      _sendOTP(newPhone); // ✅ Send OTP with loading
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Enter a valid 10-digit phone number.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
      AppBar(backgroundColor: Colors.white, title: Text('Change Phone Number')),
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 50),
              CircleAvatar(
                radius: 70,
                backgroundColor: Colors.white,
                child: Icon(Icons.phone, size: 120, color: Colors.black54),
              ),
              SizedBox(height: 50),
              Text(
                "Please Provide Your \nNew Phone Number",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 30),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: InputDecoration(
                  labelText: "New Phone",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  counterText: "",
                ),
              ),
              SizedBox(height: 20),

              // ✅ Show Loading or Send OTP Button
              _isLoading
                  ? CircularProgressIndicator(color: Colors.black) // ✅ Show Loading Animation
                  : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding:
                  EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                onPressed: _isLoading
                    ? null // ❌ Disable button when loading
                    : _navigateToOTP, // ✅ Send OTP when button clicked
                child: Text('Send OTP',
                    style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
