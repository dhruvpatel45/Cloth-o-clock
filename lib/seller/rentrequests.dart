import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_details_page.dart';

class RequestForRentScreen extends StatefulWidget {
  const RequestForRentScreen({Key? key}) : super(key: key);

  @override
  _RequestForRentScreenState createState() => _RequestForRentScreenState();
}

class _RequestForRentScreenState extends State<RequestForRentScreen> {
  List<dynamic> requests = [];
  bool isLoading = true;
  bool isError = false;

  @override
  void initState() {
    super.initState();
    fetchRentRequests();
  }

  Future<void> fetchRentRequests() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String userId = prefs.getString('userId') ?? "0";

      final response = await http.get(
        Uri.parse(
            "http://192.168.205.252/flutter_api/get_rent_requests.php?owner_id=$userId"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            requests = data['requests'];
            isLoading = false;
          });
        } else {
          setState(() {
            isError = true;
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isError = true;
        isLoading = false;
      });
      print("Error fetching rent requests: $e");
    }
  }

  Future<void> updateRequestStatus(int requestId, String status) async {
    try {
      final response = await http.post(
        Uri.parse("http://192.168.205.252/flutter_api/update_rent_request.php"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "request_id": requestId,
          "status": status,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Request $status successfully')),
          );
          fetchRentRequests(); // Refresh the list
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update request: $e')),
      );
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
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
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final cardTextColor = isDark ? Colors.white70 : Colors.black87;
    return Scaffold(
      appBar: AppBar(
        backgroundColor:  isDark ? Colors.black54 : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Rental Requests'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchRentRequests,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : isError
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 50, color: Colors.red),
            SizedBox(height: 16),
            Text('Failed to load rental requests',
                style: TextStyle(fontSize: 18)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchRentRequests,
              child: Text('Retry'),
            ),
          ],
        ),
      )
          : requests.isEmpty
          ? Center(
        child: Text('No rental requests found',
            style: TextStyle(fontSize: 18)),
      )
          : ListView.builder(
        padding: EdgeInsets.all(8),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return Card(
            elevation: 4,
            margin: EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: EdgeInsets.all(12),
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
                          width: 100,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 100,
                                height: 120,
                                color: Colors.grey[200],
                                child: Icon(Icons.image_not_supported),
                              ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request['product_name'],
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Requested by: ${request['renter_name']}',
                              style: TextStyle(fontSize: 14),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Dates: ${request['date_range']}',
                              style: TextStyle(fontSize: 14),
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'Status: ',
                                  style: TextStyle(fontSize: 14),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: getStatusColor(request['status']),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    request['status'].toString().toUpperCase(),
                                    style: TextStyle(fontSize: 12, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserDetailsPage(
                                userId: request['renter_id'].toString(),
                              ),
                            ),
                          );
                        },
                        child: Text('View User Details'),
                      ),
                      if (request['status'] == 'pending') ...[
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => updateRequestStatus(request['id'], 'accepted'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: Text('Accept'),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => updateRequestStatus(request['id'], 'rejected'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: Text('Reject'),
                        ),
                      ],
                    ],
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
