import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class ReturnRequestScreen extends StatefulWidget {
  @override
  _ReturnRequestScreenState createState() => _ReturnRequestScreenState();
}

class _ReturnRequestScreenState extends State<ReturnRequestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> rentRequests = [];
  List<dynamic> buyRequests = [];
  bool isLoading = true;
  String? errorMessage;
  String? userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserIdAndRequests();
  }

  Future<void> _loadUserIdAndRequests() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
    });

    if (userId != null) {
      await _fetchReturnRequests();
    } else {
      setState(() {
        isLoading = false;
        errorMessage = "User ID not found";
      });
    }
  }

  Future<void> _fetchReturnRequests() async {
    try {
      final response = await http.post(
        Uri.parse("http://192.168.205.252/flutter_api/fetch_return_requests.php"),
        body: {'seller_id': userId!},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          rentRequests = data['rent_requests'] ?? [];
          buyRequests = data['buy_requests'] ?? [];
          isLoading = false;
          errorMessage = null;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = "Failed to load return requests: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Connection error: ${e.toString()}";
      });
    }
  }

  Future<void> _updateRequestStatus(int requestId, String status, String type) async {
    try {
      final response = await http.post(
        Uri.parse("http://192.168.205.252/flutter_api/update_return_status.php"),
        body: {
          'request_id': requestId.toString(),
          'status': status,
          'type': type,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Request $status successfully. Email sent to customer.')),
          );
          await _fetchReturnRequests();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update request: ${data['error'] ?? 'Unknown error'}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update request: $e')),
      );
    }
  }

  String _getImageUrl(dynamic productImages) {
    try {
      if (productImages is String) {
        final decoded = jsonDecode(productImages);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded[0];
        }
        return productImages;
      } else if (productImages is List && productImages.isNotEmpty) {
        return productImages[0];
      }
    } catch (e) {
      print("Error parsing product images: $e");
    }
    return '';
  }

  Widget _buildTimeRemaining(Map<String, dynamic> request, String type) {
    if (request['expire_time'] == null) {
      return Text(
        'Delivery time not recorded',
        style: TextStyle(color: Colors.grey, fontSize: 12),
      );
    }

    try {
      final expireTime = DateTime.parse(request['expire_time']);
      final now = DateTime.now();
      final isExpired = now.isAfter(expireTime);

      if (isExpired) {
        return Text(
          'Return period expired',
          style: TextStyle(color: Colors.red, fontSize: 12),
        );
      } else {
        final remaining = expireTime.difference(now);
        if (type == 'rent') {
          return Text(
            '${remaining.inHours} hours ${remaining.inMinutes.remainder(60)} minutes remaining',
            style: TextStyle(color: Colors.green, fontSize: 12),
          );
        } else {
          return Text(
            '${remaining.inDays} days ${remaining.inHours.remainder(24)} hours remaining',
            style: TextStyle(color: Colors.green, fontSize: 12),
          );
        }
      }
    } catch (e) {
      return Text(
        'Time calculation error',
        style: TextStyle(color: Colors.grey, fontSize: 12),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Return Requests'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Rent Returns'),
            Tab(text: 'Buy Returns'),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!))
          : TabBarView(
        controller: _tabController,
        children: [
          _buildRequestList(rentRequests, 'rent'),
          _buildRequestList(buyRequests, 'buy'),
        ],
      ),
    );
  }

  Widget _buildRequestList(List<dynamic> requests, String type) {
    if (requests.isEmpty) {
      return Center(child: Text('No ${type} return requests found'));
    }

    return RefreshIndicator(
      onRefresh: _fetchReturnRequests,
      child: ListView.builder(
        padding: EdgeInsets.all(8),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return _buildRequestCard(request, type);
        },
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request, String type) {
    final imageUrl = _getImageUrl(request['product_images']);
    final fullImageUrl = imageUrl.isNotEmpty
        ? "http://192.168.205.252/flutter_api/$imageUrl"
        : '';

    final deliveredTime = request['delivered_timing'] != null
        ? DateFormat('MMM dd, yyyy HH:mm').format(
        DateTime.parse(request['delivered_timing']))
        : 'Delivery time not recorded';

    final isExpired = request['is_expired'] ?? false;

    return Card(
      margin: EdgeInsets.all(8),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: fullImageUrl.isNotEmpty
                        ? DecorationImage(
                      image: NetworkImage(fullImageUrl),
                      fit: BoxFit.cover,
                    )
                        : null,
                    color: Colors.grey[200],
                  ),
                  child: fullImageUrl.isEmpty
                      ? Icon(Icons.image, size: 40, color: Colors.grey)
                      : null,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request['product_name'] ?? 'Unknown Product',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Customer: ${request['full_name'] ?? 'Unknown User'}',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Delivered: $deliveredTime',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      SizedBox(height: 4),
                      _buildTimeRemaining(request, type),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Reason: ${request['reason'] ?? 'No reason provided'}',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 8),
            if (request['status'] == 'Pending') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: isExpired
                        ? null
                        : () => _updateRequestStatus(
                        request['id'], 'Accepted', type),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: Text('Accept'),
                  ),
                  ElevatedButton(
                    onPressed: () => _updateRequestStatus(
                        request['id'], 'Rejected', type),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: Text('Reject'),
                  ),
                ],
              ),
            ] else ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(request['status']).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  request['status'].toString().toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(request['status']),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
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
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}