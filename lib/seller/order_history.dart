import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

import 'rentalpolicy.dart';

class OrderHistoryScreen extends StatefulWidget {
  @override
  _OrderHistoryScreenState createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> buyOrders = [];
  List<Map<String, dynamic>> rentOrders = [];
  bool isLoading = true;
  bool _isSendingEmail = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchOrderHistory();
  }

  Future<void> fetchOrderHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');

    if (userId == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse("http://192.168.205.252/flutter_api/order_history.php?user_id=$userId"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          buyOrders = (data['buy_orders'] as List).map((item) => Map<String, dynamic>.from(item)).toList();
          rentOrders = (data['rent_orders'] as List).map((item) => Map<String, dynamic>.from(item)).toList();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _sendRentalReminderEmails(Map<String, dynamic> order) async {
    if (_isSendingEmail) return;

    // Show success immediately
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reminder sent successfully!')),
    );

    setState(() => _isSendingEmail = true);

    // Process in background
    Future.microtask(() async {
      try {
        await http.post(
          Uri.parse("http://192.168.205.252/flutter_api/send_rental_reminders.php"),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'order_id': order['id']}),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Email sent, but delivery might be delayed')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSendingEmail = false);
        }
      }
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Order History'),
          actions: [
            IconButton(
              icon: Icon(Icons.info_outline),
              onPressed: ()
              {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RentalPolicyScreen()),
                );
              },
            ),
          ],
          bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'Purchases'),
                Tab(text: 'Rentals'),
              ],
              ),
          ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList(buyOrders),
          _buildOrderList(rentOrders),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<Map<String, dynamic>> orders) {
    if (orders.isEmpty) {
      return Center(child: Text('No orders found'));
    }

    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    List<String> images = [];
    try {
      if (order['product_images'] is String) {
        images = List<String>.from(json.decode(order['product_images']));
      } else if (order['product_images'] is List) {
        images = List<String>.from(order['product_images']);
      }
    } catch (e) {
      print('Error parsing images: $e');
    }

    String imageUrl = images.isNotEmpty
        ? "http://192.168.205.252/flutter_api/${images[0]}"
        : '';

    bool showReminderButton = false;
    if (order['end_date'] != null) {
      DateTime endDate = DateTime.parse(order['end_date']);
      DateTime today = DateTime.now();
      showReminderButton = _isSameDay(endDate, today);
    }

    return Card(
      margin: EdgeInsets.all(12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                    image: imageUrl.isNotEmpty
                        ? DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: imageUrl.isEmpty
                      ? Icon(Icons.image, size: 40, color: Colors.grey)
                      : null,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['product_name'] ?? 'Unknown Product',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),
                      Text(
                        '₹${(double.tryParse(order['product_price'].toString()) ?? 0).toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 4),
                      Text('Quantity: ${order['quantity'] ?? 1}', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Divider(height: 1),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order #${order['order_number'] ?? ''}'),
                    SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy').format(DateTime.parse(order['created_at'])),
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order['delivery_status'] ?? '').withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    (order['delivery_status']?.toString().toUpperCase()) ?? 'UNKNOWN',
                    style: TextStyle(
                      color: _getStatusColor(order['delivery_status'] ?? ''),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (order['start_date'] != null && order['end_date'] != null) ...[
              SizedBox(height: 8),
              Divider(height: 1),
              SizedBox(height: 8),
              Text('Rental Period:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('${order['start_date']} to ${order['end_date']}'),
            ],
            if (showReminderButton) ...[
              SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isSendingEmail ? null : () => _sendRentalReminderEmails(order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  minimumSize: Size(double.infinity, 48),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.email),
                    SizedBox(width: 8),
                    Text('Send Reminder Emails'),
                  ],
                ),
              ),
            ],
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}