import 'package:flutter/material.dart';
import 'package:hello/user/returnpolicy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'returnRentProduct_page.dart';
import 'returnBuyProduct_page.dart';

class ReturnProductPage extends StatefulWidget {
  @override
  _ReturnProductPageState createState() => _ReturnProductPageState();
}

class _ReturnProductPageState extends State<ReturnProductPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> rentProducts = [];
  List<dynamic> sellProducts = [];
  bool isLoading = true;
  String? userId;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserIdAndProducts();
  }

  Future<void> _loadUserIdAndProducts() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
    });

    if (userId != null) {
      await _fetchRentReturnProducts();
      await _fetchSellReturnProducts();
    } else {
      setState(() {
        isLoading = false;
        errorMessage = "User ID not found";
      });
    }
  }

  Future<void> _fetchRentReturnProducts() async {
    try {
      final url = Uri.parse("http://192.168.205.252/flutter_api/get_rent_return_products.php?user_id=$userId");
      final response = await http.get(url);

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      final decodedResponse = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (decodedResponse['success'] == true) {
          setState(() {
            rentProducts = decodedResponse['rent_products'] ?? [];
            isLoading = false;
            errorMessage = null;
          });
        } else {
          setState(() {
            isLoading = false;
            errorMessage = decodedResponse['message'] ?? "Failed to load products";
          });
        }
      } else {
        setState(() {
          isLoading = false;
          errorMessage = "Server error: ${response.statusCode}";
        });
      }
    } on FormatException catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Invalid server response format";
      });
      print("JSON Format Error: $e");
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Connection error: ${e.toString()}";
      });
      print("Network Error: $e");
    }
  }
  Future<void> _fetchSellReturnProducts() async {
    try {
      final url = Uri.parse("http://192.168.205.252/flutter_api/get_sell_return_products.php?user_id=$userId");
      final response = await http.get(url);

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      final decodedResponse = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (decodedResponse['success'] == true) {
          setState(() {
            sellProducts = decodedResponse['sell_products'] ?? [];

            isLoading = false;
            errorMessage = null;
          });
        } else {
          setState(() {
            isLoading = false;
            errorMessage = decodedResponse['message'] ?? "Failed to load products";
          });
        }
      } else {
        setState(() {
          isLoading = false;
          errorMessage = "Server error: ${response.statusCode}";
        });
      }
    } on FormatException catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Invalid server response format";
      });
      print("JSON Format Error: $e");
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Connection error: ${e.toString()}";
      });
      print("Network Error: $e");
    }
  }



  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Return Products'),
              IconButton(
                icon: Icon(Icons.policy),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => returnPolicyScreen()),
                  );
                },
              ),
            ],
          ),
          backgroundColor: Colors.white,
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Rent'),
              Tab(text: 'Buy'),
            ],
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.brown,
          ),
        ),
        body: Container(
          color: Colors.white,
          child: Column(
            children: [
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : TabBarView(
                  controller: _tabController,
                  children: [
                    RentProductsTab(products: rentProducts),
                    BuyProductsTab(products: sellProducts),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RentProductsTab extends StatelessWidget {
  final List<dynamic> products;

  const RentProductsTab({Key? key, required this.products}) : super(key: key);

  String getFormattedDate(String dateTimeString) {
    try {
      DateTime dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
    } catch (e) {
      return dateTimeString;
    }
  }

  String _getImageUrl(dynamic productImages) {
    try {
      // Handle case where product_images is a JSON string
      if (productImages is String) {
        final decoded = jsonDecode(productImages);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded[0];
        }
        return productImages;
      }
      // Handle case where product_images is already a List
      else if (productImages is List && productImages.isNotEmpty) {
        return productImages[0];
      }
      // Handle case where product_images is a direct URL string
      else if (productImages is String) {
        return productImages;
      }
    } catch (e) {
      print("Error parsing product images: $e");
    }
    return ''; // Return empty string if no image found
  }

  @override
  Widget build(BuildContext context) {
    return products.isEmpty
        ? Center(child: Text("No rent products to return"))
        : GridView.builder(
      padding: EdgeInsets.all(10),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.50,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final item = products[index];
        bool isExpired = false;
        DateTime? expireTime;

        try {
          if (item['expire_time'] != null) {
            expireTime = DateTime.parse(item['expire_time']);
            isExpired = DateTime.now().isAfter(expireTime);
          }
        } catch (e) {
          print("Error parsing expire_time: $e");
        }

        final imageUrl = _getImageUrl(item['product_images']);
        final fullImageUrl = imageUrl.isNotEmpty
            ? "http://192.168.205.252/flutter_api/$imageUrl"
            : '';

        return GestureDetector(
          onTap: isExpired
              ? () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text("Product Expired"),
                content: Text("The return period for this product has expired."),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("OK"),
                  ),
                ],
              ),
            );
          }
              : () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReturnRentProductPage(
                  productId: item['product_id']?.toString() ?? '',
                  imagePath: fullImageUrl,
                  title: item['product_name'] ?? '',
                  price: "₹${item['product_price']?.toString() ?? '0.00'}",
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Stack(
                    children: [
                      if (fullImageUrl.isNotEmpty)
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              child: Image.network(
                                fullImageUrl,
                                height: 230,
                                width: 170,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      color: Colors.grey[200],
                                      child: Icon(Icons.image_not_supported,
                                          color: Colors.grey),
                                    ),
                              )
                          ),
                        )
                      else
                        Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: Icon(Icons.image_not_supported,
                                size: 50,
                                color: Colors.grey),
                          ),
                        ),
                      if (isExpired)
                        Container(
                          color: Colors.brown.withOpacity(0.3),
                          child: Center(
                            child: Text(
                              'Return Period Expired',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['product_name'] ?? 'No title',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 5),
                    Text(
                      "₹${item['product_price']?.toString() ?? '0.00'}",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 5),
                    if (item['delivered_timing'] != null)
                      Text(
                        'Delivered: ${getFormattedDate(item['delivered_timing'])}',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    SizedBox(height: 5),
                    if (item['expire_time'] != null)
                      Text(
                        'Expires: ${getFormattedDate(item['expire_time'])}',
                        style: TextStyle(
                          color: isExpired ? Colors.red : Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class BuyProductsTab extends StatelessWidget {
  final List<dynamic> products;

  const BuyProductsTab({Key? key, required this.products}) : super(key: key);
  String getFormattedDate(String dateTimeString) {
    try {
      DateTime dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
    } catch (e) {
      return dateTimeString;
    }
  }

  String _getImageUrl(dynamic productImages) {
    try {
      // Handle case where product_images is a JSON string
      if (productImages is String) {
        final decoded = jsonDecode(productImages);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded[0];
        }
        return productImages;
      }
      // Handle case where product_images is already a List
      else if (productImages is List && productImages.isNotEmpty) {
        return productImages[0];
      }
      // Handle case where product_images is a direct URL string
      else if (productImages is String) {
        return productImages;
      }
    } catch (e) {
      print("Error parsing product images: $e");
    }
    return ''; // Return empty string if no image found
  }

  @override
  Widget build(BuildContext context) {
    return products.isEmpty
        ? Center(child: Text("No Buy products to return"))
        : GridView.builder(
      padding: EdgeInsets.all(10),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.50,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final item = products[index];
        bool isExpired = false;
        DateTime? expireTime;

        try {
          if (item['expire_time'] != null) {
            expireTime = DateTime.parse(item['expire_time']);
            isExpired = DateTime.now().isAfter(expireTime);
          }
        } catch (e) {
          print("Error parsing expire_time: $e");
        }

        final imageUrl = _getImageUrl(item['product_images']);
        final fullImageUrl = imageUrl.isNotEmpty
            ? "http://192.168.205.252/flutter_api/$imageUrl"
            : '';

        return GestureDetector(
          onTap: isExpired
              ? () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text("Product Expired"),
                content: Text("The return period for this product has expired."),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("OK"),
                  ),
                ],
              ),
            );
          }
              : () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReturnBuyProductPage(
                  productId: item['product_id']?.toString() ?? '',
                  imagePath: fullImageUrl,
                  title: item['product_name'] ?? '',
                  price: "₹${item['product_price']?.toString() ?? '0.00'}",
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Stack(
                    children: [
                      if (fullImageUrl.isNotEmpty)
                        Expanded(
                          child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              child: Image.network(
                                fullImageUrl,
                                height: 230,
                                width: 170,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      color: Colors.grey[200],
                                      child: Icon(Icons.image_not_supported,
                                          color: Colors.grey),
                                    ),
                              )
                          ),
                        )
                      else
                        Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: Icon(Icons.image_not_supported,
                                size: 50,
                                color: Colors.grey),
                          ),
                        ),
                      if (isExpired)
                        Container(
                          color: Colors.brown.withOpacity(0.3),
                          child: Center(
                            child: Text(
                              'Return Period Expired',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['product_name'] ?? 'No title',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 5),
                    Text(
                      "₹${item['product_price']?.toString() ?? '0.00'}",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 5),
                    if (item['delivered_timing'] != null)
                      Text(
                        'Delivered: ${getFormattedDate(item['delivered_timing'])}',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    SizedBox(height: 5),
                    if (item['expire_time'] != null)
                      Text(
                        'Expires: ${getFormattedDate(item['expire_time'])}',
                        style: TextStyle(
                          color: isExpired ? Colors.red : Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}