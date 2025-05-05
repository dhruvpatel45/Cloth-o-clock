import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'home_page.dart';

class ViewProducts extends StatefulWidget {
  const ViewProducts({Key? key}) : super(key: key);

  @override
  State<ViewProducts> createState() => _ViewProductsState();
}

class _ViewProductsState extends State<ViewProducts> {
  List<Map<String, dynamic>> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProducts();
  }

  // ✅ Fetch products uploaded by this user
  Future<void> _fetchUserProducts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString('userId') ?? "0";

    var url = Uri.parse("http://192.168.205.252/flutter_api/fetch_user_products.php");

    try {
      var response = await http.post(
        url,
        body: {"user_id": userId},
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            products = List<Map<String, dynamic>>.from(data['products']);
            isLoading = false;
          });
        } else {
          _showError(data['message']);
        }
      } else {
        _showError("Error: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Failed to load products: $e");
    }
  }

  // ✅ Show error message
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    setState(() {
      isLoading = false;
    });
  }

  // ✅ Show product details with images and delete button inside a curved white background
  void showDetailsPopup(BuildContext context, Map<String, dynamic> product) {
    List<String> imagePaths = List<String>.from(product['product_images']);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Center(
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 3,
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ Product Images with PageView
                SizedBox(
                  width: 300,
                  height: 300,
                  child: PageView.builder(
                    itemCount: imagePaths.length,
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          "http://192.168.205.252/flutter_api/" + imagePaths[index],
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // ✅ Rent or Sell Indicator
                Text(
                  product['table_name'] == 'Rent' ? "Product Type: Rent" : "Product Type: Sell",
                  style: TextStyle(
                    fontSize: 16,
                    color: product['table_name'] == 'Rent' ? Colors.orange : Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                // ✅ Product Name
                Text(
                  product['product_name'],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),

                // ✅ Product Size
                Text(
                  "Size: ${product['product_size']}",
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 5),

                // ✅ Product Price
                Text(
                  "Price: ₹${product['product_price']}",
                  style: const TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                // ✅ Product Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    product['product_desc'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 10),

                // ✅ Additional Details
                Text(
                  "Quantity: ${product['quantity']}",
                  style: const TextStyle(fontSize: 16, color: Colors.blue),
                ),
                Text(
                  "UPI ID: ${product['upi_id']}",
                  style: const TextStyle(fontSize: 16, color: Colors.orange),
                ),
                Text(
                  "Category: ${product['category']}",
                  style: const TextStyle(fontSize: 16, color: Colors.purple),
                ),
                const SizedBox(height: 20),

                // ✅ Buttons (Close & Delete)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Close Button
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        "Close",
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),

                    // Delete Button
                    ElevatedButton(
                      onPressed: () => _deleteProduct(context, product),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        "Delete",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Delete product and update UI
  Future<void> _deleteProduct(BuildContext context, Map<String, dynamic> product) async {
    String productId = product['product_id'].toString();
    String tableName = product['table_name'] == 'Rent' ? 'rent_product' : 'sell_product';

    var url = Uri.parse("http://192.168.205.252/flutter_api/delete_product.php");

    try {
      var response = await http.post(
        url,
        body: {
          "product_id": productId,
          "table_name": tableName,
        },
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['success']) {
          Navigator.pop(context); // Close popup
          setState(() {
            // ✅ Remove product from list after deletion
            products.removeWhere((item) => item['product_id'].toString() == productId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Product deleted successfully!")),
          );
        } else {
          _showError(data['message']);
        }
      } else {
        _showError("Error: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Failed to delete product: $e");
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
        title: const Text("My Products"),
        backgroundColor:  isDark ? Colors.black54 : Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.home, color: isDark ? Colors.white : Colors.black),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => SellerHomePage()),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
          ? const Center(child: Text("No products uploaded yet."))
          : Padding(
        padding: const EdgeInsets.all(10.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.8,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            var product = products[index];
            List<String> imagePaths = List<String>.from(product['product_images']);
            return GestureDetector(
              onTap: () => showDetailsPopup(context, product),
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          "http://192.168.205.252/flutter_api/" + imagePaths[0],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        product['product_name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        "₹${product['product_price']}",
                        style: const TextStyle(fontSize: 14, color: Colors.green),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
                      child: Text(
                        product['table_name'] == 'Rent' ? "For Rent" : "For Sale",
                        style: TextStyle(
                          fontSize: 14,
                          color: product['table_name'] == 'Rent' ? Colors.orange : Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
