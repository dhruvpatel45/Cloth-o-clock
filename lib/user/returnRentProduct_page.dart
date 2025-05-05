import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReturnRentProductPage extends StatefulWidget {
  final String productId;
  final String imagePath;
  final String title;
  final String price;

  ReturnRentProductPage({
    required this.productId,
    required this.imagePath,
    required this.title,
    required this.price,
  });

  @override
  _ReturnRentProductPageState createState() => _ReturnRentProductPageState();
}

class _ReturnRentProductPageState extends State<ReturnRentProductPage> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> submitReturnRequest() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');

    if (userId == null || _reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a reason or login again.")),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Check eligibility first
    final eligibilityResponse = await http.get(
      Uri.parse("http://192.168.205.252/flutter_api/check_buy_return_eligible.php?user_id=$userId&product_id=${widget.productId}"),
    );

    if (eligibilityResponse.statusCode == 200) {
      final data = json.decode(eligibilityResponse.body);
      if (data['is_eligible'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Return period has expired (7 days after delivery).')),
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to check return eligibility.")),
      );
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    // Submit return request
    final returnResponse = await http.post(
      Uri.parse("http://192.168.205.21/flutter_api/submit_rent_return_request.php"),
      body: {
        "product_id": widget.productId,
        "user_id": userId,
        "reason": _reasonController.text.trim(),
      },
    );

    print("Response body: ${returnResponse.body}");

    setState(() {
      _isSubmitting = false;
    });

    if (returnResponse.statusCode == 200) {
      if (returnResponse.body.trim() == "success") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Return request submitted.")),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        try {
          final Map<String, dynamic> resData = jsonDecode(returnResponse.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(resData['message'] ?? "Failed to submit return request.")),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Unexpected error: ${returnResponse.body}")),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to submit return request.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Return Product'),
        backgroundColor: Colors.brown[50],
      ),
      body: Container(
        color: Colors.brown[50],
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    widget.imagePath,
                    width: 100,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.error, size: 100, color: Colors.red),
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        widget.price,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                hintText: 'Reason for returning the product...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : submitReturnRequest,
                child: Text(_isSubmitting ? 'Submitting...' : 'Submit Return'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
