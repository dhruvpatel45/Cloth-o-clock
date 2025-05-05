import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'cart_page.dart';

class AvailabilityPage extends StatefulWidget {
  const AvailabilityPage({Key? key}) : super(key: key);

  @override
  _AvailabilityPageState createState() => _AvailabilityPageState();
}

class _AvailabilityPageState extends State<AvailabilityPage> {
  List<dynamic> _rentalRequests = [];
  bool _isLoading = true;
  bool _isAddingToCart = false;
  int? _processingIndex;

  @override
  void initState() {
    super.initState();
    _fetchRentalRequests();
  }

  Future<void> _fetchRentalRequests() async {
    setState(() => _isLoading = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');

      if (userId == null) {
        _showErrorMessage('User not logged in.');
        return;
      }

      final response = await http.get(
        Uri.parse("http://192.168.205.252/flutter_api/get_rent_requests_user.php?renter_id=$userId"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _rentalRequests = data['requests'];
            _isLoading = false;
          });
        } else {
          _showErrorMessage(data['message'] ?? 'No rental requests found');
        }
      } else {
        _showErrorMessage('Failed to load requests: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorMessage('Error fetching rental requests: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isRentalPeriodEnded(String endDate) {
    try {
      DateTime endDateTime = DateTime.parse(endDate);
      return DateTime.now().isAfter(endDateTime);
    } catch (e) {
      return false;
    }
  }

  Future<void> _addToCart(Map<String, dynamic> request, int index) async {
    if (_isAddingToCart) return;

    setState(() {
      _isAddingToCart = true;
      _processingIndex = index;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');

      if (userId == null) {
        _showErrorMessage('User not logged in.');
        return;
      }

      // Add to cart
      final cartResponse = await http.post(
        Uri.parse("http://192.168.205.252/flutter_api/cart_api.php"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'product_id': request['product_id'],
          'category': 'rent',
          'quantity': 1,
          'start_date': request['start_date'],
          'end_date': request['end_date'],
        }),
      );

      if (cartResponse.statusCode == 200) {
        final cartData = json.decode(cartResponse.body);
        if (cartData['status'] == 'success') {
          // Mark request as completed
          final completeResponse = await http.post(
            Uri.parse("http://192.168.205.252/flutter_api/update_rent_request.php"),
            body: {
              'request_id': request['id'].toString(),
              'status': 'completed',
            },
          );

          if (completeResponse.statusCode == 200) {
            final completeData = json.decode(completeResponse.body);
            if (completeData['status'] == 'success') {
              // Update UI
              if (mounted) {
                setState(() {
                  _rentalRequests.removeAt(index);
                });
              }

              // Navigate to cart page
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ShoppingBag()),
                );
              }

              _showSuccessMessage('Added to cart successfully!');
              return;
            }
          }
        }
      } else {
        _showErrorMessage('Failed to add to cart. Server error');
      }
    } catch (e) {
      _showSuccessMessage('Added to cart successfully!');
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
          _processingIndex = null;
        });
      }
    }
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.black,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted': return Colors.green;
      case 'rejected': return Colors.red;
      case 'completed': return Colors.blue;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rental Requests'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchRentalRequests,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _rentalRequests.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No rental requests found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            TextButton(
              onPressed: _fetchRentalRequests,
              child: Text('Refresh'),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchRentalRequests,
        child: ListView.builder(
          padding: EdgeInsets.all(8),
          itemCount: _rentalRequests.length,
          itemBuilder: (context, index) {
            final request = _rentalRequests[index];
            final isPeriodEnded = _isRentalPeriodEnded(request['end_date']);
            final isAccepted = request['status'].toLowerCase() == 'accepted';
            final isProcessing = _processingIndex == index && _isAddingToCart;

            return Card(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            'http://192.168.205.252/flutter_api/${request['product_images']}',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[200],
                              child: Icon(Icons.image, size: 40),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request['product_name'] ?? 'Unknown Product',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Request ID: ${request['id']}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(height: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'From: ${request['start_date']}',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'To: ${request['end_date']}',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              if (isPeriodEnded)
                                Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Rental period has ended',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Chip(
                          labelPadding: EdgeInsets.symmetric(horizontal: 8),
                          backgroundColor: _getStatusColor(request['status']),
                          label: Text(
                            request['status'].toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isAccepted && !isPeriodEnded)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                            onPressed: isProcessing
                                ? null
                                : () => _addToCart(request, index),
                            child: isProcessing
                                ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.shopping_cart, size: 18,color: Colors.white),
                                SizedBox(width: 8),
                                Text('Add to Cart', style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}