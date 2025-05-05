import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LikePage extends StatefulWidget {
  @override
  _LikePageState createState() => _LikePageState();
}

class _LikePageState extends State<LikePage> {
  List<dynamic> likedRentProducts = [];
  List<dynamic> likedBuyProducts = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchLikedProducts();
  }

  Future<void> fetchLikedProducts() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString('userId') ?? "0";

    if (userId == null) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
      showSnackBar('Please login to view liked products');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            "http://192.168.205.252/flutter_api/get_liked_products.php?user_id=$userId"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            likedRentProducts = data['likes']
                .where((product) => product['category'] == 'rent')
                .toList();
            likedBuyProducts = data['likes']
                .where((product) => product['category'] == 'buy')
                .toList();
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
            hasError = true;
          });
          showSnackBar(data['message'] ?? 'Failed to load liked products');
        }
      } else {
        setState(() {
          isLoading = false;
          hasError = true;
        });
        showSnackBar('Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
      showSnackBar('Network error: ${e.toString()}');
    }
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> unlikeProduct(String productId, String category) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString('userId') ?? "0";

    if (userId == null) {
      showSnackBar('Please login to manage likes');
      return;
    }

    // Debugging: Log category and productId
    print("Unliking product with ID: $productId, category: $category");

    try {
      final response = await http.post(
        Uri.parse("http://192.168.205.252/flutter_api/unlike_product.php"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "user_id": userId,
          "product_id": productId,
          "category": category,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          fetchLikedProducts();  // Refresh the list
          showSnackBar(data['message'] ?? 'Product removed from liked items');
        } else {
          showSnackBar(data['message'] ?? 'Failed to unlike product');
        }
      } else {
        showSnackBar('Server error: ${response.statusCode}');
      }
    } catch (e) {
      showSnackBar('Network error: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Liked Products"),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              tabs: [
                Tab(text: 'Rent (${likedRentProducts.length})'),
                Tab(text: 'Buy (${likedBuyProducts.length})'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildProductList(likedRentProducts, 'Rent'),
                  _buildProductList(likedBuyProducts, 'Buy'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList(List<dynamic> products, String category) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red),
            SizedBox(height: 20),
            Text(
              "Failed to load $category products",
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: fetchLikedProducts,
              child: Text("Retry"),
            ),
          ],
        ),
      );
    }

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              "No liked $category products yet",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "Tap the heart icon on products to add them here",
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final images = product['product_images'];

        final imageUrl = (images != null && images.isNotEmpty)
            ? "http://192.168.205.252/flutter_api/${images[0]}"
            : "https://via.placeholder.com/150";

        return Card(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            contentPadding: EdgeInsets.all(12),
            leading: SizedBox(
              width: 60,
              height: 60,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl.isNotEmpty ? imageUrl : "",
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    } else {
                      return Center(child: CircularProgressIndicator());
                    }
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: Icon(Icons.broken_image, color: Colors.grey[700]),
                    );
                  },
                ),
              ),
            ),
            title: Text(product['product_name']),
            subtitle: Text('₹${product['product_price']}'),
            trailing: IconButton(
              icon: Icon(Icons.favorite, color: Colors.red),
              onPressed: () {
                unlikeProduct(product['id'].toString(), category);
              },
            ),
          ),
        );
      },
    );
  }
}
