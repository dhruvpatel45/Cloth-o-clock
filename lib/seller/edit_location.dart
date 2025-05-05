import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditLocationScreen extends StatefulWidget {
  final String initialAddress;
  final double latitude;
  final double longitude;

  EditLocationScreen({
    required this.initialAddress,
    required this.latitude,
    required this.longitude,
  });

  @override
  _EditLocationScreenState createState() => _EditLocationScreenState();
}

class _EditLocationScreenState extends State<EditLocationScreen> {
  late MapController _mapController;
  late double _latitude;
  late double _longitude;
  late TextEditingController _addressController;
  final String mapTilerKey = 'ZPGB1U9xpuz5SNWpzn8V';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _latitude = widget.latitude;
    _longitude = widget.longitude;
    _addressController = TextEditingController(text: widget.initialAddress);
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
      _mapController.move(LatLng(_latitude, _longitude), 17.0);
    } catch (e) {
      print("Location error: $e");
    }
  }

  Future<void> _saveAddressToDatabase() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User not logged in")),
      );
      return;
    }

    String address = _addressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a full address")),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('http://192.168.205.252/flutter_api/save_or_update_location.php'),
      body: {
        'user_id': userId,
        'latitude': _latitude.toString(),
        'longitude': _longitude.toString(),
        'address': address,
      },
    );

    final result = json.decode(response.body);
    if (result['status'] == 'success') {
      Navigator.pop(context, {
        'address': address,
        'latitude': _latitude,
        'longitude': _longitude,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${result['message']}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.black : Colors.white;
    final appBarColor = isDark ? Colors.grey[900] : Colors.brown[100];
    final textFieldColor = isDark ? Colors.grey[850] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          "Edit Delivery Location",
          style: TextStyle(color: textColor),
        ),
        backgroundColor: appBarColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(_latitude, _longitude),
                      initialZoom: 17.0,
                      onPositionChanged: (position, _) {
                        setState(() {
                          _latitude = position.center!.latitude;
                          _longitude = position.center!.longitude;
                        });
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                        'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=$mapTilerKey',
                        additionalOptions: {'accessToken': mapTilerKey},
                        tileProvider: NetworkTileProvider(),
                      ),
                    ],
                  ),
                  Center(
                    child: Icon(Icons.location_pin,
                        size: 50, color: Colors.red),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                child: Column(
                  children: [
                    TextField(
                      controller: _addressController,
                      maxLines: null,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: "Enter your address",
                        hintStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: textFieldColor,
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 14, horizontal: 16),
                      ),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _saveAddressToDatabase,
                      child: Text("Save Address"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.teal[300] : Colors.teal[300],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        textStyle: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
