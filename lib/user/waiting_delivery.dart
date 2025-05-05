import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'delivery_status.dart';

class WaitingDeliveryScreen extends StatefulWidget {
  @override
  _WaitingDeliveryScreenState createState() => _WaitingDeliveryScreenState();
}

class _WaitingDeliveryScreenState extends State<WaitingDeliveryScreen> {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserOrders();
  }

  Future<void> fetchUserOrders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');

    if (userId == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse("http://192.168.205.252/flutter_api/user_orders.php?user_id=$userId"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          orders = List<Map<String, dynamic>>.from(data['orders']);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching user orders: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Orders'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : orders.isEmpty
          ? Center(child: Text('No orders yet'))
          : ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return orderCard(order, context);
        },
      ),
    );
  }

  Widget orderCard(Map<String, dynamic> order, BuildContext context) {
    List<String> images = [];

    try {
      if (order['product_images'] is String) {
        final decoded = json.decode(order['product_images']);
        if (decoded is List) {
          images = decoded.map((item) => item.toString()).toList();
        }
      } else if (order['product_images'] is List) {
        images = order['product_images'].map((item) => item.toString()).toList();
      }
    } catch (e) {
      print('Error parsing product images: $e');
    }

    String firstImage = images.isNotEmpty ? images[0] : '';

    return Card(
      margin: EdgeInsets.all(10),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.network(
                  "http://192.168.205.252/flutter_api/$firstImage",
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(Icons.image),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['product_name'],
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 5),
                      Text('Order #${order['order_number']}'),
                      SizedBox(height: 5),
                      Text('Qty: ${order['quantity']}'),
                      SizedBox(height: 5),
                      Text('₹${_formatPrice(order['product_price'])}'),
                    ],
                  ),
                ),
              ],
            ),
            Divider(),
            Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              order['delivery_status'],
              style: TextStyle(
                color: _getStatusColor(order['delivery_status']),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DeliveryStatusScreen(
                      items: [order],
                      totalAmount: order['total_amount'],
                      address: order['delivery_address'],
                      userRole: 'Customer and Seller both',
                      isPaymentCompleted: true,
                    ),
                  ),
                );
              },
              child: Text('Track Order'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(dynamic price) {
    final parsed = double.tryParse(price?.toString() ?? '');
    return parsed?.toStringAsFixed(2) ?? '0.00';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'shipped':
        return Colors.blue;
      case 'processing':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
