import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'edit_location.dart';
import 'payment.dart';

class DeliveryAddressScreen extends StatefulWidget {
  final List<Map<String, dynamic>> items;

  DeliveryAddressScreen({required this.items});

  @override
  _DeliveryAddressScreenState createState() => _DeliveryAddressScreenState();
}

class _DeliveryAddressScreenState extends State<DeliveryAddressScreen> {
  String address = '';
  double latitude = 0.0;
  double longitude = 0.0;

  @override
  void initState() {
    super.initState();
    fetchUserAddress();
  }

  Future<void> fetchUserAddress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');

    if (userId != null) {
      try {
        var response = await http.post(
          Uri.parse('http://192.168.205.252/flutter_api/get_location.php'),
          body: {'user_id': userId},
        );

        if (response.statusCode == 200) {
          var data = json.decode(response.body);

          if (data['status'] == 'success') {
            setState(() {
              address = data['address'] ?? '';
              latitude = double.tryParse(data['latitude'].toString()) ?? 0.0;
              longitude = double.tryParse(data['longitude'].toString()) ?? 0.0;
            });
          }
        }
      } catch (e) {
        print('Fetch address error: $e');
      }
    }
  }

  double getTotal() {
    return widget.items.fold(0.0, (sum, item) {
      double price = double.tryParse(item['product_price'].toString()) ?? 0.0;
      int quantity = item['quantity'] ?? 1;
      return sum + (price * quantity);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark ? Colors.black : Colors.white;
    final cardColor = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.grey[300] : Colors.grey[700];
    final borderColor = isDark ? Colors.grey[700]! : Colors.black12;

    double totalAmount = getTotal();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Delivery Location', style: TextStyle(color: textColor)),
        backgroundColor: backgroundColor,
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
      ),
      body: Container(
        color: backgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Address Section
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: borderColor,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:  Colors.blue.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_on_outlined, color: Colors.blue),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            address.isNotEmpty ? address : "No address available",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditLocationScreen(
                                initialAddress: address,
                                latitude: latitude,
                                longitude: longitude,
                              ),
                            ),
                          );

                          if (result != null && result is Map<String, dynamic>) {
                            setState(() {
                              address = result['address'] ?? '';
                              latitude = result['latitude'] ?? 0.0;
                              longitude = result['longitude'] ?? 0.0;
                            });
                          }
                        },
                        icon: Icon(Icons.edit, color: Colors.white, size: 18),
                        label: Text('Edit Address', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              // Cart Items Section
              Expanded(
                child: widget.items.isNotEmpty
                    ? ListView.builder(
                  itemCount: widget.items.length,
                  itemBuilder: (context, index) {
                    var item = widget.items[index];

                    String name = item['product_name'] ?? 'Unknown Product';
                    String price = item['product_price']?.toString() ?? '0.00';
                    List<String> imagePaths = List<String>.from(item['product_images'] ?? []);
                    String image = imagePaths.isNotEmpty ? imagePaths[0] : '';
                    int quantity = item['quantity'] ?? 1;

                    return productItem(name, '₹$price', image, quantity, cardColor!, textColor, secondaryTextColor!);
                  },
                )
                    : Center(
                  child: Text(
                    'Your cart is empty',
                    style: TextStyle(fontSize: 18, color: textColor),
                  ),
                ),
              ),
              Divider(color: borderColor),
              Text('Bill summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              SizedBox(height: 8),
              summaryRow('Total MRP (Inc all Taxes)', '₹$totalAmount', textColor),
              summaryRow('Shipping', 'Free', textColor),
              Divider(color: borderColor),
              summaryRow('Total Amount', '₹$totalAmount', textColor, isBold: true),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentScreen(
                          items: widget.items,
                          address: address,
                          upiId: "Your upi id",
                        ),
                      ),
                    );
                  },
                  child: Text('Make Payment', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget productItem(String title, String price, String imagePath, int quantity, Color cardColor,
      Color textColor, Color secondaryColor) {
    final String imageUrl = imagePath.isNotEmpty
        ? "http://192.168.205.252/flutter_api/$imagePath"
        : "https://via.placeholder.com/150";

    return Card(
      margin: EdgeInsets.symmetric(vertical: 6),
      elevation: 3,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) =>
                progress == null ? child : CircularProgressIndicator(),
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 70,
                  height: 70,
                  color: Colors.grey[300],
                  child: Icon(Icons.broken_image, size: 40, color: Colors.grey[700]),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                  SizedBox(height: 4),
                  Text(price,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                  Text('Qty: $quantity',
                      style: TextStyle(fontSize: 14, color: secondaryColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget summaryRow(String title, String amount, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
          Text(amount,
              style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
        ],
      ),
    );
  }
}
