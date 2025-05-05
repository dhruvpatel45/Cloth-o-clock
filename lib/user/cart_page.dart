import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'delivery_address.dart';

class ShoppingBag extends StatefulWidget {
  @override
  _ShoppingBagState createState() => _ShoppingBagState();
}

class _ShoppingBagState extends State<ShoppingBag> {
  List<Map<String, dynamic>> items = [];
  bool isLoading = true;
  int total = 0;

  @override
  void initState() {
    super.initState();
    fetchCartItems();
  }

  Future<void> fetchCartItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');

    if (userId == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final buyResponse = await http.get(Uri.parse(
          "http://192.168.205.252/flutter_api/cart_api.php?user_id=$userId&category=buy"));
      final rentResponse = await http.get(Uri.parse(
          "http://192.168.205.252/flutter_api/cart_api.php?user_id=$userId&category=rent"));

      if (buyResponse.statusCode == 200 && rentResponse.statusCode == 200) {
        final buyData = json.decode(buyResponse.body);
        final rentData = json.decode(rentResponse.body);

        setState(() {
          items = [
            ...(buyData['items'] as List).map((item) => item as Map<String, dynamic>),
            ...(rentData['items'] as List).map((item) => item as Map<String, dynamic>)
          ];
          total = calculateTotal();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching cart items: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  int calculateTotal() {
    return items.fold(0, (sum, item) {
      double price = double.tryParse(item['product_price'].toString()) ?? 0.0;
      int quantity = item['quantity'] ?? 1;

      // For rental items, calculate based on rental duration
      if (item['start_date'] != null && item['end_date'] != null) {
        try {
          DateTime startDate = DateTime.parse(item['start_date']);
          DateTime endDate = DateTime.parse(item['end_date']);
          int rentalDays = endDate.difference(startDate).inDays + 1;
          return sum + (price * quantity * rentalDays).toInt();
        } catch (e) {
          print("Error parsing rental dates: $e");
          return sum + (price * quantity).toInt();
        }
      }
      // For regular purchase items
      return sum + (price * quantity).toInt();
    });
  }

  Future<void> updateQuantity(int index, int newQuantity) async {
    if (newQuantity <= 0) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    var item = items[index];
    bool isRent = item['start_date'] != null;

    try {
      final response = await http.put(
        Uri.parse("http://192.168.205.252/flutter_api/cart_api.php"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'cart_id': item['id'],
          'quantity': newQuantity,
          'category': isRent ? 'rent' : 'buy',
          'user_id': userId,
          'start_date': item['start_date'],
          'end_date': item['end_date'],
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          items[index]['quantity'] = newQuantity;
          total = calculateTotal();
        });
      }
    } catch (e) {
      print("Error updating quantity: $e");
    }
  }

  Future<void> removeItem(int index) async {
    var item = items[index];
    bool isRent = item['start_date'] != null;

    try {
      final response = await http.delete(
        Uri.parse("http://192.168.205.252/flutter_api/cart_api.php"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'cart_id': item['id'],
          'category': isRent ? 'rent' : 'buy',
          'user_id': item['user_id'],
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          items.removeAt(index);
          total = calculateTotal();
        });
      }
    } catch (e) {
      print("Error removing item: $e");
    }
  }

  void moveToWishlist(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${items[index]['product_name']} moved to wishlist'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      appBar: AppBar(
        title: Text("Shopping Bag"),
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (items.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return shoppingItem(
                      index,
                      items[index]['product_name'],
                      items[index]['product_images'] is List
                          ? 'http://192.168.205.252/flutter_api/${items[index]['product_images'][0]}'
                          : 'http://192.168.205.252/flutter_api/${items[index]['product_images']}',
                      items[index]['product_price'],
                      items[index]['quantity'],
                      items[index]['start_date'] != null
                          ? "${items[index]['start_date']} - ${items[index]['end_date']}"
                          : null,
                    );
                  },
                ),
              )
            else
              Center(child: Text("Your cart is empty")),
            Divider(),
            billSummary(total),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: items.isNotEmpty
                  ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        DeliveryAddressScreen(items: items),
                  ),
                );
              }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? Colors.white : Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
              child: Text("Check out",
                  style: TextStyle(
                      color: isDarkMode ? Colors.black : Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget shoppingItem(int index, String name, String imageUrl, dynamic price, int quantity, String? rentalDates) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    double itemPrice = double.tryParse(price.toString()) ?? 0.0;
    double totalPrice = itemPrice * quantity;

    // Calculate rental price if applicable
    if (rentalDates != null) {
      try {
        List<String> dates = rentalDates.split(" - ");
        DateTime startDate = DateTime.parse(dates[0]);
        DateTime endDate = DateTime.parse(dates[1]);
        int rentalDays = endDate.difference(startDate).inDays + 1;
        totalPrice = itemPrice * quantity * rentalDays;
      } catch (e) {
        print("Error calculating rental price: $e");
      }
    }

    return Card(
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Image.network(imageUrl, width: 120, height: 120, fit: BoxFit.cover),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black)),
                      SizedBox(height: 5),
                      Text("₹$itemPrice",
                          style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? Colors.white : Colors.black)),
                      if (rentalDates != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 5),
                            Text("Rental Dates: $rentalDates",
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode ? Colors.white70 : Colors.black54)),
                          ],
                        ),
                      SizedBox(height: 5),
                      Text("Total: ₹${totalPrice.toStringAsFixed(2)}",
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black)),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove_circle_outline,
                                color: isDarkMode ? Colors.white : Colors.black),
                            onPressed: () => updateQuantity(index, quantity - 1),
                          ),
                          Text(quantity.toString(),
                              style: TextStyle(
                                  fontSize: 16,
                                  color: isDarkMode ? Colors.white : Colors.black)),
                          IconButton(
                            icon: Icon(Icons.add_circle_outline,
                                color: isDarkMode ? Colors.white : Colors.black),
                            onPressed: () => updateQuantity(index, quantity + 1),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => removeItem(index),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? Colors.white : Colors.black),
                  child: Text("Remove",
                      style: TextStyle(color: isDarkMode ? Colors.black : Colors.white)),
                ),
                ElevatedButton(
                  onPressed: () => moveToWishlist(index),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? Colors.white : Colors.black),
                  child: Text("Move to Wishlist",
                      style: TextStyle(color: isDarkMode ? Colors.black : Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget billSummary(int total) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Bill Summary",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black)),
        SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Total MRP (Incl. Taxes)",
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
            Text("₹$total",
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Shipping",
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
            Text("Free",
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
          ],
        ),
        Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Total Amount",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black)),
            Text("₹$total",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black)),
          ],
        ),
      ],
    );
  }
} 