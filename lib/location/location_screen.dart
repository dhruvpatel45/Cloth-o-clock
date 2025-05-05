import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:location/location.dart' as location;
import 'package:permission_handler/permission_handler.dart' as permission_handler;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationScreen extends StatefulWidget {
  final Function(String, double, double) onSaveLocation;

  const LocationScreen({required this.onSaveLocation, Key? key}) : super(key: key);

  @override
  _LocationScreenState createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  double? _latitude;
  double? _longitude;
  String _fullAddress = '';
  bool _isLoading = false;
  String _errorMessage = '';

  final String mapTilerApiKey = 'Your map key';
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
  }

  Future<void> getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final permission = await permission_handler.Permission.location.request();

    if (permission.isGranted) {
      final locationService = location.Location();
      locationService.changeSettings(accuracy: location.LocationAccuracy.high);

      bool serviceEnabled = await locationService.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await locationService.requestService();
        if (!serviceEnabled) {
          setState(() {
            _errorMessage = 'Location service is disabled.';
            _isLoading = false;
          });
          return;
        }
      }

      final permissionGranted = await locationService.hasPermission();
      if (permissionGranted != location.PermissionStatus.granted) {
        final requested = await locationService.requestPermission();
        if (requested != location.PermissionStatus.granted) {
          setState(() {
            _errorMessage = 'Location permission denied.';
            _isLoading = false;
          });
          return;
        }
      }

      try {
        final currentLocation = await locationService.getLocation();
        _latitude = currentLocation.latitude;
        _longitude = currentLocation.longitude;

        if (_latitude != null && _longitude != null) {
          _mapController.move(LatLng(_latitude!, _longitude!), 16.0);
          await _getAddressFromCoordinates(_latitude!, _longitude!);
        }
      } catch (e) {
        _errorMessage = 'Error getting location: $e';
      }
    } else {
      _errorMessage = 'Location permission denied.';
    }

    setState(() => _isLoading = false);
  }

  Future<void> _getAddressFromCoordinates(double lat, double lon) async {
    final url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'FlutterApp/1.0 (clothoclock2024@gmail.com)'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] ?? {};

        String building = address['building'] ?? '';
        String houseNumber = address['house_number'] ?? '';
        String road = address['road'] ?? '';
        String street = address['suburb'] ?? address['neighbourhood'] ?? '';
        String area = address['county'] ?? '';
        String city = address['city'] ?? address['town'] ?? address['village'] ?? '';
        String state = address['state'] ?? '';
        String country = address['country'] ?? '';
        String postcode = address['postcode'] ?? '';
        String fallback = data['display_name'] ?? '';

        String fullAddress = '''
${building.isNotEmpty ? '$building, ' : ''}${houseNumber.isNotEmpty ? '$houseNumber, ' : ''}${road.isNotEmpty ? '$road, ' : ''}${street.isNotEmpty ? '$street, ' : ''}${area.isNotEmpty ? '$area, ' : ''}${city.isNotEmpty ? '$city, ' : ''}${state.isNotEmpty ? '$state, ' : ''}${country.isNotEmpty ? '$country, ' : ''}${postcode.isNotEmpty ? '$postcode' : ''}
'''.trim();

        setState(() {
          _fullAddress = fullAddress.isNotEmpty ? fullAddress : fallback;
        });
      } else {
        _fullAddress = 'Error: ${response.statusCode}';
      }
    } catch (e) {
      _fullAddress = 'Error fetching address: $e';
    }
  }

  Future<void> _saveLocation() async {
    if (_latitude == null || _longitude == null || _fullAddress.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId != null) {
      final response = await http.post(
        Uri.parse('http://192.168.205.252/flutter_api/save_or_update_location.php'),
        body: {
          'user_id': userId,
          'latitude': _latitude.toString(),
          'longitude': _longitude.toString(),
          'address': _fullAddress,
        },
      );

      if (response.statusCode == 200) {
        print('Location saved successfully');
      } else {
        print('Failed to save location');
      }
    }

    widget.onSaveLocation(_fullAddress, _latitude!, _longitude!);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: Text('Select Location', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      body: Column(
        children: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(_errorMessage, style: TextStyle(color: color.error)),
            ),
          if (_latitude != null && _longitude != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Card(
                color: isDark ? Colors.grey[850] : Colors.white,
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '📍 $_fullAddress\n\nLat: $_latitude\nLng: $_longitude',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16),
                  ),
                ),
              ),
            ),
          if (_latitude != null && _longitude != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: _saveLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color.primary,
                  foregroundColor: color.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Save Location'),
              ),
            ),
          const SizedBox(height: 10),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(_latitude ?? 28.7041, _longitude ?? 77.1025),
                    initialZoom: 16.0,
                    onTap: (_, point) async {
                      setState(() {
                        _latitude = point.latitude;
                        _longitude = point.longitude;
                        _isLoading = true;
                      });
                      await _getAddressFromCoordinates(point.latitude, point.longitude);
                      setState(() => _isLoading = false);
                      _mapController.move(point, 16);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: isDark
                          ? 'https://api.maptiler.com/maps/basic-dark/{z}/{x}/{y}.png?key=$mapTilerApiKey'
                          : 'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=$mapTilerApiKey',
                      additionalOptions: {'accessToken': mapTilerApiKey},
                      tileProvider: NetworkTileProvider(),
                    ),
                    MarkerLayer(
                      markers: [
                        if (_latitude != null && _longitude != null)
                          Marker(
                            point: LatLng(_latitude!, _longitude!),
                            width: 60,
                            height: 60,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              child: const Icon(Icons.location_pin, size: 40, color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
