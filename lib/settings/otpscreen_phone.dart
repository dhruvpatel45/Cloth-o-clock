import 'package:flutter/material.dart';
import 'editprofile.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class OTPScreenPhone extends StatefulWidget {
  final String newValue;
  final Function(String) onVerified;

  OTPScreenPhone({required this.newValue, required this.onVerified});

  @override
  _OTPScreenPhoneState createState() => _OTPScreenPhoneState();
}

class _OTPScreenPhoneState extends State<OTPScreenPhone> {
  List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());  // Change to 6
  List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  String? userId;// Change to 6

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();  // ✅ Fetch userId on screen load
  }

  void _verifyOTP() async {
    if (userId == null) {
      await _fetchUserDetails();  // ✅ Fetch userId if not available
    }
    String otp = _otpControllers.map((controller) => controller.text).join();
    if (otp.length == 6) {
      final url = "http://192.168.205.252/flutter_api/verify_phone_otp.php";

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'otp': otp,
          'new_phone': widget.newValue, // Pass new phone number for update
        }),
      );

      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        widget.onVerified(widget.newValue);
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'])),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Enter a valid 6-digit OTP.")),
      );
    }
  }

  Future<void> _fetchUserDetails() async {
    final String apiUrl = 'http://192.168.205.252/flutter_api/get_user_details.php';

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
      appBar: AppBar(backgroundColor: Colors.white, title: Text('Enter OTP')),
      body: Container(
        color: Colors.white,
        width: double.infinity,
        height: double.infinity,
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 70,),
            Text("Verification",style: TextStyle(fontSize: 50,fontWeight: FontWeight.bold),),
            SizedBox(height: 100,),
            Center(
              child: Text("Verification code has been sent to\nyou on your updated Phone Number",style: TextStyle(fontSize: 20,),),
            ),
            SizedBox(height: 35),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {  // Change to 6
                return Container(
                  width: 45,
                  margin: EdgeInsets.symmetric(horizontal: 5),
                  child: TextField(
                    controller: _otpControllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(border: OutlineInputBorder(), counterText: "",filled: true,fillColor: Colors.white,),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {  // Change to 5 for 6 digits
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
            SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              onPressed: _verifyOTP,
              child: Text('Verify OTP', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
            Spacer(),
          ],
        ),
      ),
    );
  }
}
