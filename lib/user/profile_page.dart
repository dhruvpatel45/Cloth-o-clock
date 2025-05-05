import 'package:flutter/material.dart';
import 'package:hello/settings/about_us_page.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hello/settings/settings.dart';
import 'package:hello/settings/editprofile.dart';
import 'home_page.dart';
import 'package:hello/wishlist/like_page.dart';
import 'buy_page.dart';
import 'rent_page.dart';
import 'feedback_page.dart';


class ProfilePage extends StatefulWidget {
  final String userId;

  ProfilePage({required this.userId});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = "";
  String email = "";
  String phone = "";
  String? profileImageUrl;
  File? _profileImage;
  int _selectedIndex = 3;
  bool _isBottomNavVisible = true;
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  // Cache user details
  static Map<String, dynamic>? _cachedUserDetails;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    // Return if already loading
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Use cached data if available
      if (_cachedUserDetails != null) {
        _updateUserDetails(_cachedUserDetails!);
        return;
      }

      await _fetchUserDetails();
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load profile. Pull down to refresh.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchUserDetails() async {
    final String apiUrl = 'http://192.168.205.252/flutter_api/get_user_details.php';

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');

    if (userId == null) {
      throw Exception('User not logged in.');
    }

    final Map<String, dynamic> requestBody = {
      'user_id': userId,
    };

    final response = await http.post(
      Uri.parse(apiUrl),
      body: jsonEncode(requestBody),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final Map<String, dynamic>? data = jsonDecode(response.body);

      if (data != null && data['status'] == 'success') {
        _cachedUserDetails = data; // Cache the data
        _updateUserDetails(data);
      } else {
        throw Exception(data?['message'] ?? 'Failed to fetch user details.');
      }
    } else {
      throw Exception('Error: ${response.statusCode}. Please try again later.');
    }
  }

  void _updateUserDetails(Map<String, dynamic> data) {
    if (mounted) {
      setState(() {
        name = data['full_name'] ?? 'N/A';
        email = data['email'] ?? 'N/A';
        phone = data['contact_number'] ?? 'N/A';
        profileImageUrl = data['profile_image'];
        _hasError = false;
      });
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          name: name,
          email: email,
          phone: phone,
          imagePath: profileImageUrl,
          userId: widget.userId,
        ),
      ),
    );

    if (result != null && result == 'updated') {
      // Invalidate cache and reload
      _cachedUserDetails = null;
      _loadUserDetails();
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    Widget page;
    switch (index) {
      case 0: page = UserHomePage(); break;
      case 1: page = RentPage(); break;
      case 2: page = BuyPage(); break;
      case 3: page = ProfilePage(userId: ''); break;
      default: return;
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => page));
  }


  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final bgColor = isDarkMode ? Colors.grey[900] : Colors.white;
    final cardColor = isDarkMode ? Colors.grey[800] : Colors.white;
    final iconColor = isDarkMode ? Colors.white70 : Colors.black54;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: TextStyle(color: textColor)),
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          if (_hasError)
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _loadUserDetails,
            ),
        ],
      ),
      backgroundColor: bgColor,
      body: RefreshIndicator(
        onRefresh: _loadUserDetails,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                if (_isLoading && !_hasError)
                  Center(child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  )),

                if (_hasError)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(_errorMessage, style: TextStyle(color: Colors.red)),
                    ),
                  ),

                if (!_isLoading && !_hasError) ...[
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : profileImageUrl != null
                              ? NetworkImage(profileImageUrl!) as ImageProvider
                              : null,
                          child: _profileImage == null && profileImageUrl == null
                              ? Icon(Icons.person, size: 60, color: textColor)
                              : null,
                        ),
                        const SizedBox(height: 10),
                        Text(name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                        Text(email, style: TextStyle(color: isDarkMode ? Colors.grey[300] : Colors.grey[700])),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildListTile(Icons.phone, "+91 $phone", iconColor, textColor),
                  Divider(color: isDarkMode ? Colors.grey[700] : Colors.grey[300]),

                  _buildListTile(Icons.feedback_outlined, "Feedback", iconColor, textColor, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => FeedbackPage()));
                  }),
                  _buildListTile(Icons.settings, "Settings", iconColor, textColor, onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => SettingsScreen(),
                    ));
                  }),
                  _buildListTile(Icons.info_outline, "About Us", iconColor, textColor, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => AboutUsPage()));
                  }),

                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? Colors.white : Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    ),
                    onPressed: _navigateToEditProfile,
                    child: Text('Edit Profile', style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.black : Colors.white)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Visibility(
        visible: _isBottomNavVisible,
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.green,
          unselectedItemColor: textColor,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.lock_clock), label: 'Rent'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Buy'),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, Color iconColor, Color textColor, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: TextStyle(fontSize: 16, color: textColor)),
      onTap: onTap,
    );
  }
}