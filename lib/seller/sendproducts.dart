import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SendProductsScreen extends StatefulWidget {
  @override
  _SendProductsScreenState createState() => _SendProductsScreenState();
}

class _SendProductsScreenState extends State<SendProductsScreen> {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSellerOrders();
  }

  Future<void> fetchSellerOrders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sellerId = prefs.getString('userId');

    if (sellerId == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse("http://192.168.205.252/flutter_api/seller_orders.php?seller_id=$sellerId"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            orders = List<Map<String, dynamic>>.from(data['orders']);
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching seller orders: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateDeliveryStatus(String orderId, String status) async {
    try {
      final response = await http.put(
        Uri.parse("http://192.168.205.252/flutter_api/update_delivery_status.php"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'order_id': orderId,
          'status': status,
        }),
      );

      if (response.statusCode == 200) {
        // If status is delivered, also add to return tables
        if (status == 'delivered') {
          await _addToReturnTables(orderId);
        }
        fetchSellerOrders();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status')),
        );
      }
    } catch (e) {
      print("Error updating delivery status: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  Future<void> _addToReturnTables(String orderId) async {
    try {
      final response = await http.post(
        Uri.parse("http://192.168.205.252/flutter_api/add_to_return_tables.php"),
        body: {
          'order_id': orderId,
        },
      );

      if (response.statusCode != 200) {
        print("Failed to add to return tables: ${response.body}");
      }
    } catch (e) {
      print("Error adding to return tables: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Orders'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : orders.isEmpty
          ? Center(child: Text('No orders to manage'))
          : ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return orderCard(order);
        },
      ),
    );
  }

  Widget orderCard(Map<String, dynamic> order) {
    // Safe handling of product_images
    List<String> images = [];

    try {
      if (order['product_images'] is String) {
        // Handle JSON string case
        dynamic decoded = json.decode(order['product_images']);
        if (decoded is List) {
          images = decoded.map((item) => item.toString()).toList();
        }
      } else if (order['product_images'] is List) {
        // Handle already parsed list case
        images = order['product_images'].map((item) => item.toString()).toList();
      }
    } catch (e) {
      print("Error parsing product images: $e");
      print("Raw product_images value: ${order['product_images']}");
    }

    String firstImage = images.isNotEmpty
        ? "http://192.168.205.252/flutter_api/${images[0]}"
        : 'https://via.placeholder.com/150';

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
                  firstImage,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(Icons.image, size: 80),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['product_name'] ?? 'No Name',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 5),
                      Text('Order #${order['order_number'] ?? 'N/A'}'),
                      SizedBox(height: 5),
                      Text('Qty: ${order['quantity'] ?? 1}'),
                      SizedBox(height: 5),
                      Text('₹${double.tryParse(order['product_price']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}'),
                    ],
                  ),
                ),
              ],
            ),
            Divider(),
            Text('Delivery Address:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(order['delivery_address'] ?? 'No address provided'),
            Divider(),
            Text(
              'Status: ${order['delivery_status'] ?? 'pending'}',
              style: TextStyle(
                color: _getStatusColor(order['delivery_status'] ?? 'pending'),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if ((order['delivery_status'] ?? 'pending') != 'delivered')
                  ElevatedButton(
                    onPressed: () => updateDeliveryStatus(order['id'].toString(), 'processing'),
                    child: Text('Processing'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                  ),
                if ((order['delivery_status'] ?? 'pending') != 'delivered')
                  ElevatedButton(
                    onPressed: () => updateDeliveryStatus(order['id'].toString(), 'shipped'),
                    child: Text('Shipped'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ElevatedButton(
                  onPressed: () => updateDeliveryStatus(order['id'].toString(), 'delivered'),
                  child: Text('Delivered'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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