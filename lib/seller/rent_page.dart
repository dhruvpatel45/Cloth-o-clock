import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:hello/seller/returnrequests.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'order_history.dart';
import 'rent_detail_page.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_page.dart';
import 'addproducts.dart';
import 'profile_page.dart';
import 'buy_page.dart';
import 'rent_page.dart';
import 'returnpolicy.dart';
import 'package:hello/wishlist/like_page.dart' as Like_buy;
import 'cart_page.dart' as Cart_buy;
import 'package:hello/settings/settings.dart';
import 'package:hello/settings/support_page.dart';
import 'buy_detail_page.dart';
import 'feedback_page.dart';
import 'package:hello/settings/about_us_page.dart';
import 'rentrequests.dart';
import 'sendproducts.dart';
import 'viewproducts.dart';
import 'returnproduct_page.dart';
import 'availability.dart';
import 'waiting_delivery.dart';

class RentPage extends StatefulWidget {
  @override
  _RentPageState createState() => _RentPageState();
}

class _RentPageState extends State<RentPage> {
  File? _profileImage;
  String name = "";
  String email = "";
  String? profileImageUrl;
  int _selectedIndex = 1;
  bool _isMenuOpen = false;
  bool _isBottomNavVisible = true;
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _rentProducts = [];

  @override
  void initState() {
    super.initState();
    _fetchRentProducts();
    _fetchUserDetails();

    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (_isBottomNavVisible) {
          setState(() {
            _isBottomNavVisible = false;
          });
        }
      } else if (_scrollController.position.userScrollDirection ==
          ScrollDirection.forward) {
        if (!_isBottomNavVisible) {
          setState(() {
            _isBottomNavVisible = true;
          });
        }
      }
    });
  }

  Future<void> _fetchUserDetails() async {
    final String apiUrl = 'http://192.168.205.53/flutter_api/get_user_details.php';

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');

      if (userId == null) {
        _showErrorMessage('User not logged in.');
        return;
      }

      final Map<String, dynamic> requestBody = {
        'user_id': userId,
      };

      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(requestBody),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic>? data = jsonDecode(response.body);

        if (data != null && data['status'] == 'success') {
          setState(() {
            name = data['full_name'] ?? 'N/A';
            email = data['email'] ?? 'N/A';
            profileImageUrl = data['profile_image'] ?? null;
          });
        } else {
          _showErrorMessage(data?['message'] ?? 'Failed to fetch user details.');
        }
      } else {
        _showErrorMessage('Error: ${response.statusCode}. Please try again later.');
      }
    } catch (e) {
      _showErrorMessage('An unexpected error occurred. Please try again.');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _fetchRentProducts() async {
    try {
      final response = await http.get(
        Uri.parse("http://192.168.205.252/flutter_api/get_rent_products.php"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['success'] == true &&
            data['products'] != null) {
          setState(() {
            _rentProducts = List<Map<String, dynamic>>.from(data['products']);
          });
        } else {
          print("API returned success: false or no products");
        }
      } else {
        print("Failed to fetch products. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching rent products: $e");
    }
  }


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 2) {
      _showImagePickerOptions(context); // Show modal with image selection options
    } else {
      // Handle other navigation logic
      Widget page;
      switch (index) {
        case 0:
          page = SellerHomePage();
          break;
        case 1:
          page = RentPage();
          break;
        case 3:
          page = BuyPage();
          break;
        case 4:
          page = ProfilePage(userId: '',);
          break;
        default:
          return;
      }
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => page));
    }
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  void _showImagePickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo),
                title: Text("Select from Gallery"),
                onTap: _pickImagesFromGallery,
              ),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text("Capture from Camera"),
                onTap: _captureImageFromCamera,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImagesFromGallery() async {
    final List<XFile>? pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      List<File> images = pickedFiles.map((file) => File(file.path)).toList();
      Navigator.pop(context);
      _navigateToAddProducts(images);
    }
  }

  Future<void> _captureImageFromCamera() async {
    final XFile? capturedFile = await ImagePicker().pickImage(
        source: ImageSource.camera);
    if (capturedFile != null) {
      List<File> images = [File(capturedFile.path)];
      Navigator.pop(context);
      _navigateToAddProducts(images);
    }
  }

  void _navigateToAddProducts(List<File> images) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddProducts(selectedImages: images),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Row(
          children: [
            IconButton(icon: Icon(Icons.menu), onPressed: _toggleMenu),
            SizedBox(width: 10),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54),
                  contentPadding: EdgeInsets.symmetric(
                      vertical: 10, horizontal: 10),
                  filled: true,
                  fillColor: isDark ? Colors.grey[850] : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: cardTextColor),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10),
            IconButton(
              icon: Icon(Icons.favorite_border, color: cardTextColor),
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (context) => Like_buy.LikePage())),
            ),
            IconButton(
              icon: Icon(Icons.shopping_cart_outlined, color: cardTextColor),
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (context) => Cart_buy.ShoppingBag())),
            ),
          ],
        ),
      ),
      body: Container(
        color: backgroundColor,
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rent', style: TextStyle(fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor)),
                  SizedBox(height: 10),
                  Expanded(
                    child: _rentProducts.isEmpty
                        ? Center(child: CircularProgressIndicator())
                        : GridView.builder(
                      controller: _scrollController,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.70,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _rentProducts.length,
                      itemBuilder: (context, index) {
                        final product = _rentProducts[index];
                        final images = product['product_images'];
                        final imageUrl = (images != null && images.isNotEmpty)
                            ? "http://192.168.205.252/flutter_api/${images[0]}"
                            : "https://via.placeholder.com/150";

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    RentDetailPage(
                                      productId: int.parse(
                                          product['id'].toString()),
                                    ),
                              ),
                            );
                          },
                          child: _buildProductItem(
                            imageUrl: imageUrl,
                            title: product['product_name'],
                            price: product['product_price'].toString(),
                            textColor: cardTextColor,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            if (_isMenuOpen)
              GestureDetector(
                onTap: _toggleMenu,
                child: Container(color: Colors.black.withOpacity(0.5)),
              ),

            AnimatedPositioned(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: _isMenuOpen ? 0 : -MediaQuery
                  .of(context)
                  .size
                  .width * 0.6,
              top: 0,
              bottom: 0,
              width: MediaQuery
                  .of(context)
                  .size
                  .width * 0.6,
              child: Container(
                color: backgroundColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    UserAccountsDrawerHeader(
                      decoration: BoxDecoration(color: Colors.brown[50]),
                      margin: EdgeInsets.zero,
                      currentAccountPicture: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!) as ImageProvider
                            : profileImageUrl != null
                            ? NetworkImage(profileImageUrl!) as ImageProvider
                            : null,
                        child: _profileImage == null && profileImageUrl == null
                            ? Icon(Icons.person, size: 60)
                            : null,
                      ),
                      accountName: Text(name.isNotEmpty ? name : "Loading...",style: TextStyle(color: Colors.black),),
                      accountEmail: Text(email.isNotEmpty ? email : "Loading...",style: TextStyle(color: Colors.black),),
                    ),
                    ListTile(
                      leading: Icon(Icons.delivery_dining),
                      title: Text('Manage Orders'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SendProductsScreen()),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.people_alt_outlined),
                      title: Text('Rent Requests'),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => RequestForRentScreen()));
                      },
                    ),

                    ListTile(
                      leading: Icon(Icons.shopping_bag),
                      title: Text('My Orders'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => WaitingDeliveryScreen()),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.history),
                      title: Text('Order History'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => OrderHistoryScreen()),
                        );
                      },
                    ),

                    ListTile(
                      leading: Icon(Icons.hourglass_empty),
                      title: Text("Check Rent Status"),
                      onTap: () async {
                        // Get productId from your data source
                        final prefs = await SharedPreferences.getInstance();
                        final productId = prefs.getInt('currentProductId') ?? 0;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AvailabilityPage(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.assignment_return_outlined),
                      title: Text('Return Products'),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => returnPolicyScreen()));
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.help_outline),
                      title: Text('Support'),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => SupportPage()));
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Visibility(
        visible: _isBottomNavVisible,
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.lock_clock,), label: 'Rent'),

            BottomNavigationBarItem(
              icon: Container(
                decoration: BoxDecoration(
                  color: Colors.brown[100],
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: Offset(0, 3))
                  ],
                ),
                padding: EdgeInsets.all(10),
                child: Icon(Icons.add, color: Colors.black),
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag),
              label: 'Buy',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem({
    required String imageUrl,
    required String title,
    required String price,
    required Color textColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) =>
                  Center(
                    child: Icon(Icons.broken_image, color: textColor),
                  ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '₹$price/day',
          style: TextStyle(
            fontSize: 14,
            color: textColor.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
