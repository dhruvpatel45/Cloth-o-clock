import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReturnBuyProductPage extends StatefulWidget {
  final String productId;
  final String imagePath;
  final String title;
  final String price;

  const ReturnBuyProductPage({
    required this.productId,
    required this.imagePath,
    required this.title,
    required this.price,
    Key? key,
  }) : super(key: key);

  @override
  _ReturnBuyProductPageState createState() => _ReturnBuyProductPageState();
}

class _ReturnBuyProductPageState extends State<ReturnBuyProductPage> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> submitReturnRequest() async {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a reason for return")),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login again")),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Check eligibility first
      final eligibilityResponse = await http.get(
        Uri.parse("http://192.168.205.252/flutter_api/check_rent_return_eligible.php?user_id=$userId&product_id=${widget.productId}"),
      );

      if (eligibilityResponse.statusCode == 200) {
        final eligibilityData = json.decode(eligibilityResponse.body);
        if (eligibilityData['is_eligible'] == false) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(eligibilityData['message'] ?? 'Return period has expired (7 hours after delivery)')),
          );
          return;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to check return eligibility")),
        );
        return;
      }

      // Submit return request
      final returnResponse = await http.post(
        Uri.parse("http://192.168.205.252/flutter_api/submit_buy_return_request.php"),
        body: {
          "product_id": widget.productId,
          "user_id": userId,
          "reason": _reasonController.text.trim(),
        },
      );

      if (returnResponse.statusCode == 200) {
        try {
          final responseData = json.decode(returnResponse.body);
          if (responseData['status'] == 'success') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Return request submitted successfully")),
            );
            Navigator.popUntil(context, (route) => route.isFirst);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(responseData['message'] ?? "Failed to submit return request")),
            );
          }
        } catch (e) {
          if (returnResponse.body.trim() == "success") {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Return request submitted successfully")),
            );
            Navigator.popUntil(context, (route) => route.isFirst);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Unexpected response: ${returnResponse.body}")),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to submit return request")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Return Product'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
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
                    const Icon(Icons.error, size: 100, color: Colors.red),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.price,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              'Reason for Return',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                hintText: 'Please explain why you are returning this product...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
              ),
              maxLines: 5,
              minLines: 3,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : submitReturnRequest,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  'SUBMIT RETURN REQUEST',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}