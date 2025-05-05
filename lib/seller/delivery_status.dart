import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_page.dart';

class DeliveryStatusScreen extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String totalAmount;
  final String address;
  final String userRole;
  final bool isPaymentCompleted;

  const DeliveryStatusScreen({
    Key? key,
    required this.items,
    required this.totalAmount,
    required this.address,
    required this.userRole,
    required this.isPaymentCompleted,
  }) : super(key: key);

  void navigateHomePage(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SellerHomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final cardColor = isDarkMode ? Colors.grey[800]! : Colors.white;
    final scaffoldColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    final dividerColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
    final secondaryTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[700]!;
    final buttonColor = isDarkMode ? Colors.blue[800]! : Colors.black;

    String currentStatus = items.isNotEmpty
        ? (items[0]['delivery_status'] ?? 'pending')
        : 'pending';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Delivery Status',
          style: TextStyle(color: textColor),
        ),
        backgroundColor: isDarkMode ? Colors.grey[850]! : Colors.white,
        iconTheme: IconThemeData(color: textColor),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: scaffoldColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];

                    // Parse image safely
                    List<String> images = [];
                    try {
                      if (item['product_images'] is String) {
                        final decoded = json.decode(item['product_images']);
                        if (decoded is List) {
                          images = decoded.map((e) => e.toString()).toList();
                        }
                      } else if (item['product_images'] is List) {
                        images = item['product_images'].map<String>((e) => e.toString()).toList();
                      }
                    } catch (e) {
                      debugPrint("Image parse error: $e");
                    }

                    return productItem(
                      item['product_name'] ?? 'Unknown Product',
                      '₹${item['product_price'] ?? '0.00'}',
                      images.isNotEmpty ? images.first : '',
                      item['quantity'] ?? 1,
                      isDarkMode,
                    );
                  },
                ),
              ),
              Divider(thickness: 1, color: dividerColor),
              const SizedBox(height: 10),
              Text(
                'Total Amount: ₹$totalAmount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 10),
              addressWidget(isDarkMode),
              const SizedBox(height: 20),
              orderTrackingTimeline(currentStatus, isDarkMode),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  actionButton(
                    "Continue Shopping",
                        () => navigateHomePage(context),
                    buttonColor,
                    textColor,
                  ),
                  if (userRole == 'Customer and Seller both' &&
                      currentStatus != 'delivered')
                    actionButton(
                      "Confirm Delivery",
                          () async {
                        try {
                          final response = await http.put(
                            Uri.parse("http://192.168.205.252/flutter_api/update_delivery_status.php"),
                            headers: {'Content-Type': 'application/json'},
                            body: json.encode({
                              'order_id': items[0]['id'],
                              'status': 'delivered',
                            }),
                          );

                          if (response.statusCode == 200) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Delivery confirmed successfully!")),
                            );
                            Future.delayed(const Duration(seconds: 2), () {
                              navigateHomePage(context);
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Failed to confirm delivery")),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error: $e")),
                          );
                        }
                      },
                      buttonColor,
                      textColor,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget productItem(String title, String price, String imagePath, int quantity, bool isDarkMode) {
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[700]!;
    final cardColor = isDarkMode ? Colors.grey[800]! : Colors.white;

    final String imageUrl = imagePath.isNotEmpty
        ? "http://192.168.205.252/flutter_api/$imagePath"
        : "https://via.placeholder.com/150";

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 3,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 70,
                    height: 70,
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                    child: Icon(
                      Icons.broken_image,
                      size: 40,
                      color: isDarkMode ? Colors.grey[400]! : Colors.grey[700]!,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Text(
                    'Qty: $quantity',
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget addressWidget(bool isDarkMode) {
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final cardColor = isDarkMode ? Colors.grey[800]! : Colors.grey[200]!;
    final iconColor = isDarkMode ? Colors.white : Colors.black54;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              address,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget orderTrackingTimeline(String currentStatus, bool isDarkMode) {
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[700]!;

    List<Map<String, dynamic>> steps = [
      {
        'status': 'Order received',
        'time': DateFormat('hh:mm a, dd-MMM-yyyy').format(DateTime.now()),
        'icon': Icons.access_time,
        'isCompleted': true,
      },
      {
        'status': 'Processing',
        'time': currentStatus == 'processing' || currentStatus == 'shipped' || currentStatus == 'delivered'
            ? DateFormat('hh:mm a, dd-MMM-yyyy').format(DateTime.now().add(const Duration(minutes: 2)))
            : 'Pending',
        'icon': Icons.settings,
        'isCompleted': currentStatus == 'processing' || currentStatus == 'shipped' || currentStatus == 'delivered',
      },
      {
        'status': 'Shipped',
        'time': currentStatus == 'shipped' || currentStatus == 'delivered'
            ? DateFormat('hh:mm a, dd-MMM-yyyy').format(DateTime.now().add(const Duration(minutes: 30)))
            : 'Pending',
        'icon': Icons.local_shipping,
        'isCompleted': currentStatus == 'shipped' || currentStatus == 'delivered',
      },
      {
        'status': 'Delivered',
        'time': currentStatus == 'delivered'
            ? DateFormat('hh:mm a, dd-MMM-yyyy').format(DateTime.now().add(const Duration(hours: 2)))
            : 'Pending',
        'icon': Icons.done,
        'isCompleted': currentStatus == 'delivered',
      },
    ];

    return Column(
      children: steps.map((step) {
        final iconColor = step['isCompleted']
            ? Colors.green
            : isDarkMode ? Colors.grey[500]! : Colors.grey;
        final statusColor = step['isCompleted'] ? textColor : secondaryTextColor;
        final timeColor = step['isCompleted']
            ? secondaryTextColor
            : isDarkMode ? Colors.grey[600]! : Colors.grey[300]!;
        final lineColor = step['isCompleted']
            ? Colors.green
            : isDarkMode ? Colors.grey[500]! : Colors.grey;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Icon(
                  step['icon'],
                  size: 28,
                  color: iconColor,
                ),
                if (step != steps.last)
                  Container(
                    width: 2,
                    height: 30,
                    color: lineColor,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step['status'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                Text(
                  step['time'],
                  style: TextStyle(
                    fontSize: 14,
                    color: timeColor,
                  ),
                ),
              ],
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget actionButton(String text, VoidCallback onPressed, Color bgColor, Color textColor) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          color: Colors.white, // Keep button text white for better contrast
        ),
      ),
    );
  }
}