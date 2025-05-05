import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_page.dart'; // Import your SellerHomePage
import 'package:shared_preferences/shared_preferences.dart';


class AvailabilityPage extends StatefulWidget {
  //final String renter_id;

  //const AvailabilityPage({Key? key, required this.renter_id}) : super(key: key);
  const AvailabilityPage({Key? key}) : super(key: key);

  @override
  _AvailabilityPageState createState() => _AvailabilityPageState();
}

class _AvailabilityPageState extends State<AvailabilityPage> {
  List<dynamic> _rentalRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRentalRequests();
  }


  Future<void> _fetchRentalRequests() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');

      if (userId == null) {
        _showErrorMessage('User not logged in.');
        return;
      }
      final response = await http.get(
        Uri.parse("http://192.168.205.252/flutter_api/get_rent_requests_user.php?renter_id=${userId}"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _rentalRequests = data['requests']; // Use correct response field
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No rental requests found')),
          );
        }
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load requests')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching rental requests')),
      );
    }
  }
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _updateRequestStatus(int requestId, String status) async {
    try {
      final response = await http.post(
        Uri.parse("http://192.168.205.252/flutter_api/update_rent_request.php"),
        body: {
          'request_id': requestId.toString(),
          'status': status,
        },
      );

      if (response.statusCode == 200) {
        await _fetchRentalRequests(); // Refresh the list
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => UserHomePage()),
              (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status')),
      );
    }
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rental Requests'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _rentalRequests.isEmpty
          ? Center(child: Text('No rental requests found'))
          : ListView.builder(
        itemCount: _rentalRequests.length,
        itemBuilder: (context, index) {
          final request = _rentalRequests[index];
          return Card(
            margin: EdgeInsets.all(8),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image and Basic Info
                  Row(
                    children: [
                      Image.network(
                        'http://192.168.205.252/flutter_api/${request['product_images']}',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.image),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(request['product_name'], style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(request['date_range']),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  // Status Chip
                  Center(
                    child: Row(
                      children: [
                        Chip(
                          label: Text(
                            request['status'].toUpperCase(),
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: _getStatusColor(request['status']),
                        ),
                        SizedBox(width: 15,),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: (){},
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_bag_outlined,),
                              SizedBox(width: 5),
                              Text('Add to Cart'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
