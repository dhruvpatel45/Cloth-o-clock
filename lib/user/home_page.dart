import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'returnpolicy.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'order_history.dart';
import 'rent_page.dart' as Rent_home;
import 'buy_page.dart';
import 'profile_page.dart';
import 'package:hello/banner/banner_widget.dart';
import 'buy_detail_page.dart';
import 'package:hello/location/location_screen.dart';
import 'package:hello/wishlist/like_page.dart' as Like_home;
import 'cart_page.dart' as Cart_home;
import 'rent_detail_page.dart';
import 'package:hello/settings/support_page.dart';
import 'package:hello/settings/settings.dart';
import 'feedback_page.dart';
import 'package:hello/settings/about_us_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hello/user/returnproduct_page.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'availability.dart';
import 'Category/category.dart';
import 'Category/category_service.dart';
import 'Category/category_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'waiting_delivery.dart';

class UserHomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<UserHomePage> with AutomaticKeepAliveClientMixin {
  File? _profileImage;
  String name = "";
  String email = "";
  String? profileImageUrl;
  bool _isMenuOpen = false;
  int _selectedIndex = 0;
  int _currentBannerIndex = 0;
  late PageController _pageController;
  late Timer _bannerTimer;
  late Timer _categoryRefreshTimer;
  bool _isBottomNavVisible = true;
  late ScrollController _scrollController;

  String _selectedLocationAddress = '';
  double? _selectedLocationLatitude;
  double? _selectedLocationLongitude;

  List<File> _resizedImages = [];
  List<dynamic> _rentRandomProducts = [];
  List<dynamic> _sellRandomProducts = [];
  bool _isInitialLoad = true;
  bool _hasError = false;

  // Add this for category refresh
  late Future<List<Category>> _categoriesFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _bannerTimer = Timer.periodic(Duration(seconds: 5), _onBannerTimerTick);
    _scrollController = ScrollController();
    _fetchUserDetails();

    // Initialize categories future and refresh timer
    _categoriesFuture = CategoryService.fetchCategories();
    _categoryRefreshTimer = Timer.periodic(Duration(minutes: 5), (_) {
      _silentlyRefreshCategories();
    });

    _loadInitialData();

    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
        if (_isBottomNavVisible) {
          setState(() {
            _isBottomNavVisible = false;
          });
        }
      } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
        if (!_isBottomNavVisible) {
          setState(() {
            _isBottomNavVisible = true;
          });
        }
      }
    });
  }

  // Method to silently refresh categories
  void _silentlyRefreshCategories() {
    setState(() {
      _categoriesFuture = CategoryService.fetchCategories();
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

  Future<void> _loadInitialData() async {
    try {
      await Future.wait([
        _fetchAndSetLocation(),
        _fetchRentRandomProducts(),
        _fetchSellRandomProducts(),
      ]);

      if (mounted) {
        setState(() {
          _isInitialLoad = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialLoad = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _fetchRentRandomProducts() async {
    final response = await http.get(Uri.parse('http://192.168.205.252/flutter_api/get_random_rent_products.php'));
    if (response.statusCode == 200) {
      if (mounted) {
        setState(() {
          _rentRandomProducts = json.decode(response.body);
        });
      }
    } else {
      throw Exception('Failed to load rent products');
    }
  }

  Future<void> _fetchSellRandomProducts() async {
    final response = await http.get(Uri.parse('http://192.168.205.252/flutter_api/get_random_sell_products.php'));
    if (response.statusCode == 200) {
      if (mounted) {
        setState(() {
          _sellRandomProducts = json.decode(response.body);
        });
      }
    } else {
      throw Exception('Failed to load sell products');
    }
  }

  Future<void> _fetchAndSetLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId == null) {
      throw Exception('User ID not found');
    }

    final response = await http.post(
      Uri.parse('http://192.168.205.252/flutter_api/get_location.php'),
      body: {'user_id': userId},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        final address = data['address'] ?? '';
        final lat = double.tryParse(data['latitude']?.toString() ?? '') ?? 0.0;
        final lon = double.tryParse(data['longitude']?.toString() ?? '') ?? 0.0;

        if (mounted) {
          setState(() {
            _selectedLocationAddress = address;
            _selectedLocationLatitude = lat;
            _selectedLocationLongitude = lon;
          });
        }
      } else {
        throw Exception(data['message'] ?? 'No location found');
      }
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  @override
  void dispose() {
    _bannerTimer.cancel();
    _categoryRefreshTimer.cancel();
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Rent_home.RentPage()));
        break;
      case 2:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BuyPage()));
        break;
      case 3:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ProfilePage(userId: '')));
        break;
    }
  }

  void _toggleMenu() {
    setState(() => _isMenuOpen = !_isMenuOpen);
  }


  void _onBannerTimerTick(Timer timer) {
    if (_pageController.hasClients) {
      final nextPage = (_currentBannerIndex + 1) % 3;
      _pageController.animateToPage(
        nextPage,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  void _onPageChanged(int index) {
    if (mounted) {
      setState(() {
        _currentBannerIndex = index;
      });
    }
  }


  void _handleSaveLocation(String address, double latitude, double longitude) {
    if (mounted) {
      setState(() {
        _selectedLocationAddress = address;
        _selectedLocationLatitude = latitude;
        _selectedLocationLongitude = longitude;
      });
    }
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 50),
          SizedBox(height: 20),
          Text('Failed to load data', style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadInitialData,
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_hasError) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: _buildErrorWidget(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: Theme.of(context).iconTheme,
        title: Row(
          children: [
            IconButton(
              icon: Icon(Icons.menu),
              onPressed: _toggleMenu,
            ),
            SizedBox(width: 10),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).hintColor),
                  contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10),
            IconButton(
              icon: Icon(Icons.favorite_border),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => Like_home.LikePage()));
              },
            ),
            IconButton(
              icon: Icon(Icons.shopping_cart_outlined),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => Cart_home.ShoppingBag()));
              },
            ),
          ],
        ),
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LocationScreen(
                              onSaveLocation: _handleSaveLocation,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Theme.of(context).iconTheme.color,
                              size: 26,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedLocationAddress.isNotEmpty
                                    ? _selectedLocationAddress
                                    : "Select Location",
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: FutureBuilder<List<Category>>(
                        future: _categoriesFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting && _isInitialLoad) {
                            return Center(child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return Center(child: Text('Error loading categories', style: Theme.of(context).textTheme.bodyLarge));
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Center(child: Text('No categories found', style: Theme.of(context).textTheme.bodyLarge));
                          }

                          final categories = snapshot.data!;
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(width: 20),
                                for (int i = 0; i < categories.length; i++) ...[
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CategoryPage(
                                            categoryName: categories[i].name,
                                          ),
                                        ),
                                      );
                                    },
                                    child: CategoryWidget(
                                      categories[i].name,
                                      categories[i].imageUrl,
                                    ),
                                  ),
                                  if (i < categories.length - 1)
                                    SizedBox(width: [25.0, 32.0, 35.0][i % 3]),
                                ],
                                SizedBox(width: 20),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Container(
                      height: 200,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: 3,
                        onPageChanged: _onPageChanged,
                        itemBuilder: (context, index) {
                          return BannerWidget(index);
                        },
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        margin: EdgeInsets.symmetric(horizontal: 5),
                        height: 8,
                        width: 8,
                        decoration: BoxDecoration(
                          color: _currentBannerIndex == index
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).disabledColor,
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10),
                    child: Row(
                      children: [
                        Text('Rent Clothes', style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        )),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Row(
                      children: [
                        if (_rentRandomProducts.isNotEmpty) ...[
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RentDetailPage(productId: int.parse(_rentRandomProducts[0]['id'].toString())),
                                  ),
                                );
                              },
                              child: Column(
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: 'http://192.168.205.252/flutter_api/${jsonDecode(_rentRandomProducts[0]['product_images'])[0]}',
                                    height: 219,
                                    width: 156,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      height: 219,
                                      width: 156,
                                      color: Theme.of(context).dividerColor,
                                    ),
                                    errorWidget: (context, url, error) => Icon(Icons.error),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    _rentRandomProducts[0]['product_name'],
                                    textAlign: TextAlign.left,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 30),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RentDetailPage(productId: int.parse(_rentRandomProducts[1]['id'].toString())),
                                  ),
                                );
                              },
                              child: Column(
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: 'http://192.168.205.252/flutter_api/${jsonDecode(_rentRandomProducts[1]['product_images'])[0]}',
                                    height: 219,
                                    width: 156,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      height: 219,
                                      width: 156,
                                      color: Theme.of(context).dividerColor,
                                    ),
                                    errorWidget: (context, url, error) => Icon(Icons.error),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    _rentRandomProducts[1]['product_name'],
                                    textAlign: TextAlign.left,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          Expanded(child: SizedBox.shrink()),
                          SizedBox(width: 30),
                          Expanded(child: SizedBox.shrink()),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10),
                    child: Row(
                      children: [
                        Text('Buy Clothes', style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        )),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Row(
                      children: [
                        if (_sellRandomProducts.isNotEmpty) ...[
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BuyDetailPage(productId: int.parse(_sellRandomProducts[0]['id'].toString())),
                                  ),
                                );
                              },
                              child: Column(
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: 'http://192.168.205.252/flutter_api/${jsonDecode(_sellRandomProducts[0]['product_images'])[0]}',
                                    height: 219,
                                    width: 156,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      height: 219,
                                      width: 156,
                                      color: Theme.of(context).dividerColor,
                                    ),
                                    errorWidget: (context, url, error) => Icon(Icons.error),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    _sellRandomProducts[0]['product_name'],
                                    textAlign: TextAlign.left,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 30),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BuyDetailPage(productId: int.parse(_sellRandomProducts[1]['id'].toString())),
                                  ),
                                );
                              },
                              child: Column(
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: 'http://192.168.205.252/flutter_api/${jsonDecode(_sellRandomProducts[1]['product_images'])[0]}',
                                    height: 219,
                                    width: 156,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      height: 219,
                                      width: 156,
                                      color: Theme.of(context).dividerColor,
                                    ),
                                    errorWidget: (context, url, error) => Icon(Icons.error),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    _sellRandomProducts[1]['product_name'],
                                    textAlign: TextAlign.left,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          Expanded(child: SizedBox.shrink()),
                          SizedBox(width: 30),
                          Expanded(child: SizedBox.shrink()),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_isMenuOpen)
              GestureDetector(
                onTap: _toggleMenu,
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            AnimatedPositioned(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: _isMenuOpen ? 0 : -MediaQuery.of(context).size.width * 0.6,
              top: 0,
              bottom: 0,
              width: MediaQuery.of(context).size.width * 0.6,
              child: Container(
                color: Theme.of(context).cardColor,
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
                      leading: Icon(Icons.shopping_bag, color: Theme.of(context).iconTheme.color),
                      title: Text('My Orders', style: Theme.of(context).textTheme.bodyLarge),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => WaitingDeliveryScreen()),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.history, color: Theme.of(context).iconTheme.color),
                      title: Text('Order History', style: Theme.of(context).textTheme.bodyLarge),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => OrderHistoryScreen()),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.hourglass_empty, color: Theme.of(context).iconTheme.color),
                      title: Text("Check Rent Status", style: Theme.of(context).textTheme.bodyLarge),
                      onTap: () async {
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
                      leading: Icon(Icons.assignment_return_outlined, color: Theme.of(context).iconTheme.color),
                      title: Text('Return Products', style: Theme.of(context).textTheme.bodyLarge),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => returnPolicyScreen()));
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.help_outline, color: Theme.of(context).iconTheme.color),
                      title: Text('Support', style: Theme.of(context).textTheme.bodyLarge),
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
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.lock_clock),
              label: 'Rent',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag),
              label: 'Buy',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryWidget extends StatelessWidget {
  final String name;
  final String imageUrl;

  const CategoryWidget(this.name, this.imageUrl, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: CachedNetworkImageProvider(imageUrl),
        ),
        SizedBox(height: 8),
        Text(
          name,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}