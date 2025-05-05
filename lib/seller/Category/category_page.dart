import 'package:flutter/material.dart';
import 'package:hello/seller/rent_detail_page.dart';
import '../../user/buy_detail_page.dart';
import 'product_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

class CategoryPage extends StatelessWidget {
  final String categoryName;

  const CategoryPage({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(categoryName),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Rent"),
              Tab(text: "Buy"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Rentview(categoryName: categoryName),
            Buyview(categoryName: categoryName),
          ],
        ),
      ),
    );
  }
}

class Rentview extends StatefulWidget {
  final String categoryName;
  const Rentview({super.key, required this.categoryName});

  @override
  State<Rentview> createState() => _RentviewState();
}

class _RentviewState extends State<Rentview> {
  List<Product> products = [];
  bool isLoading = true;
  String errorMessage = '';
  final String baseUrl = 'http://192.168.205.252/flutter_api/';

  @override
  void initState() {
    super.initState();
    fetchRentProducts();
  }

  Future<void> fetchRentProducts() async {
    try {
      final response = await http.get(Uri.parse(
          '${baseUrl}category_rent_products.php?category=${widget.categoryName}'));

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          products = data.map((json) => Product.fromJson(json)).toList();
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load rent products");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  String getImageUrl(String path) {
    if (path.isEmpty) return '';

    // If path is already a complete URL, return as-is
    if (path.startsWith('http')) {
      return path;
    }

    // If path starts with uploads_products, construct full URL
    if (path.startsWith('uploads_products')) {
      return '$baseUrl$path';
    }

    // Default case - assume it's in uploads_products folder
    return '$baseUrl/uploads_products/$path';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(child: Text('Error: $errorMessage'));
    }

    return products.isEmpty
        ? const Center(child: Text("No rent products available"))
        : GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.70,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final imageUrl = getImageUrl(product.imageUrl);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    RentDetailPage(
                      productId: int.parse(
                          product.id.toString()),
                    ),
              ),
            );
          },
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 150,
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 150,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported,
                          color: Colors.grey),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "₹${product.price.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class Buyview extends StatefulWidget {
  final String categoryName;
  const Buyview({super.key, required this.categoryName});

  @override
  State<Buyview> createState() => _BuyviewState();
}

class _BuyviewState extends State<Buyview> {
  List<Product> products = [];
  bool isLoading = true;
  String errorMessage = '';
  final String baseUrl = 'http://192.168.205.252/flutter_api/';

  @override
  void initState() {
    super.initState();
    fetchSellProducts();
  }

  Future<void> fetchSellProducts() async {
    try {
      final response = await http.get(Uri.parse(
          '${baseUrl}category_sell_products.php?category=${widget.categoryName}'));

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          products = data.map((json) => Product.fromJson(json)).toList();
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load buy products");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  String getImageUrl(String path) {
    if (path.isEmpty) return '';

    // If path is already a complete URL, return as-is
    if (path.startsWith('http')) {
      return path;
    }

    // If path starts with uploads_products, construct full URL
    if (path.startsWith('uploads_products')) {
      return '$baseUrl$path';
    }

    // Default case - assume it's in uploads_products folder
    return '$baseUrl/uploads_products/$path';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(child: Text('Error: $errorMessage'));
    }

    return products.isEmpty
        ? const Center(child: Text("No products available for purchase"))
        : GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.70,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final imageUrl = getImageUrl(product.imageUrl);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    BuyDetailPage(
                      productId: int.parse(
                          product.id.toString()),
                    ),
              ),
            );
          },
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 150,
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 150,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported,
                          color: Colors.grey),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "₹${product.price.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}