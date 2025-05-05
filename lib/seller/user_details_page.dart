import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:maps_launcher/maps_launcher.dart';

class UserDetailsPage extends StatefulWidget {
  final String userId;

  const UserDetailsPage({Key? key, required this.userId}) : super(key: key);

  @override
  _UserDetailsPageState createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  Map<String, dynamic>? userDetails;
  Map<String, dynamic>? locationDetails;
  bool isLoading = true;
  bool isError = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.userId.isEmpty) {
      setState(() {
        isLoading = false;
        isError = true;
        errorMessage = "Missing user_id";
      });
    } else {
      fetchUserData();
    }
  }

  Future<void> fetchUserData() async {
    try {
      // Fetch basic user details
      final userResponse = await http.post(
        Uri.parse("http://192.168.205.252/flutter_api/get_user_details.php"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"user_id": widget.userId}),
      );

      // Fetch location details - modified to match your table structure
      final locationResponse = await http.post(
        Uri.parse("http://192.168.205.252/flutter_api/get_location_details.php"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"user_id": widget.userId}),
      );

      if (userResponse.statusCode == 200 && locationResponse.statusCode == 200) {
        final userData = json.decode(userResponse.body);
        final locationData = json.decode(locationResponse.body);

        setState(() {
          userDetails = userData;
          locationDetails = locationData;
          isLoading = false;

          // Check if location was found - modified for your table structure
          if (locationData['status'] != 'success' ||
              locationData['latitude'] == null ||
              locationData['longitude'] == null) {
            errorMessage = locationData['message'] ?? 'Location data not available for this user';
          }
        });
      } else {
        setState(() {
          isError = true;
          isLoading = false;
          errorMessage = "Failed to load user data. Status code: ${userResponse.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        isError = true;
        isLoading = false;
        errorMessage = "Error fetching user details: ${e.toString()}";
      });
      print("Error fetching user details: $e");
    }
  }

  Future<void> _openMap(double latitude, double longitude, String label) async {
    try {
      await MapsLauncher.launchCoordinates(latitude, longitude, label);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch maps: ${e.toString()}')),
      );
    }
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
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
        title: Text('User Details'),
        backgroundColor:  isDark ? Colors.black54 : Colors.white,
        elevation: 0,
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
            Text(errorMessage ?? 'Error loading data',
                style: TextStyle(fontSize: 18)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchUserData,
              child: Text('Retry'),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage:
                    userDetails?['profile_image'] != null
                        ? NetworkImage(
                        userDetails!['profile_image'])
                        : null,
                    child: userDetails?['profile_image'] == null
                        ? Icon(Icons.person, size: 50)
                        : null,
                  ),
                  SizedBox(height: 16),
                  Text(
                    userDetails?['full_name'] ?? 'No Name',
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Location Information Card
            _buildInfoCard('Location Information', [
              if (locationDetails?['latitude'] != null &&
                  locationDetails?['longitude'] != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (locationDetails?['address'] != null)
                      _buildDetailItem(
                        Icons.location_on,
                        'Address',
                        locationDetails!['address'],
                      ),
                    SizedBox(height: 12),
                    _buildDetailItem(
                      Icons.map,
                      'Coordinates',
                      '${locationDetails!['latitude']}, ${locationDetails!['longitude']}',
                    ),
                    SizedBox(height: 12),
                    Center(
                      child: ElevatedButton(
                        onPressed: () => _openMap(
                          double.parse(locationDetails!['latitude'].toString()),
                          double.parse(locationDetails!['longitude'].toString()),
                          userDetails?['full_name'] ?? 'User Location',
                        ),
                        child: Text('View on Map'),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  errorMessage ?? 'Location information not available for this user',
                  style: TextStyle(color: Colors.grey),
                ),
            ]),
          ],
        ),
      ),
    );
  }
}