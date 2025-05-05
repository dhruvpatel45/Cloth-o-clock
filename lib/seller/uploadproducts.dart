import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hello/seller/viewproducts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UploadProducts extends StatelessWidget {
  final String option;
  final List<File> images;
  final String productName;
  final String productPrice;
  final String productDesc;
  final String productSize;
  final int quantity;
  final String category;
  final String? gender;
  final String upiId;

  UploadProducts({
    required this.option,
    required this.images,
    required this.productName,
    required this.productPrice,
    required this.productDesc,
    required this.productSize,
    required this.quantity,
    required this.category,
    this.gender,
    required this.upiId,
  });

  Future<void> _uploadProduct(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString('userId') ?? "0";

    if (userId == "0") {
      _showError(context, "❌ User is not logged in!");
      return;
    }

    String tableName = option == "Rent" ? "rent_product" : "sell_product";
    String apiUrl = "http://192.168.205.252/flutter_api/upload_product.php";

    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.fields['table_name'] = tableName;
      request.fields['user_id'] = userId;
      request.fields['product_name'] = productName;
      request.fields['product_size'] = productSize;
      request.fields['product_price'] = productPrice;
      request.fields['product_desc'] = productDesc;
      request.fields['upi_id'] = upiId; // Ensure UPI ID is included
      request.fields['category'] = category;
      request.fields['gender'] = gender ?? '';
      request.fields['quantity'] = quantity.toString();

      if (images.isNotEmpty) {
        for (var i = 0; i < images.length; i++) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'product_images[]',
              images[i].path,
            ),
          );
        }
      }

      var response = await request.send();
      String responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);
      print("API Response: $jsonResponse"); // Debug print

      if (response.statusCode == 200) {
        if (jsonResponse['success']) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewProducts(),
            ),
          );
        } else {
          _showError(context, "❌ Failed to upload product: ${jsonResponse['message']}");
        }
      } else {
        _showError(context, "❌ Error: ${response.statusCode}");
      }
    } catch (e) {
      _showError(context, "❌ Error uploading product: $e");
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white),
      body: Container(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        child: Align(
          alignment: Alignment(0.0, -0.6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset('assets/tickmark.png', width: 150, height: 150),
              const SizedBox(height: 20),
              Text(
                "Uploading Product...",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: 160,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _uploadProduct(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? Colors.black54 : Colors.black54,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text(
                    "Upload Now",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}