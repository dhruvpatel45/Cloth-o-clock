import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'delivery_status.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Payment Screen',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          color: Colors.white,
          elevation: 1,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        buttonTheme: ButtonThemeData(buttonColor: Colors.blue),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[900]!,
        appBarTheme: AppBarTheme(
          color: Colors.grey[900],
          elevation: 1,
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        buttonTheme: ButtonThemeData(buttonColor: Colors.blue),
      ),
      themeMode: ThemeMode.system,
      home: PaymentScreen(
        items: [],
        address: '123 Main St, City, Country',
        upiId: 'your-upi-id',
      ),
    );
  }
}

class PaymentScreen extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final String address;
  final String upiId;

  const PaymentScreen({
    Key? key,
    required this.items,
    required this.address,
    required this.upiId,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isProcessing = false;
  bool _isUploading = false;
  String? _userId;
  File? _paymentScreenshot;
  final ImagePicker _picker = ImagePicker();
  final List<Map<String, dynamic>> _upiApps = [
    {
      'name': 'Pay with UPI',
      'scheme': 'upi://pay',
      'color': Colors.blue,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('userId');
    });
  }

  double getTotalAmount() {
    return widget.items.fold(0.0, (sum, item) {
      final price = double.tryParse(item['product_price'].toString()) ?? 0.0;
      final quantity = item['quantity'] is int ? item['quantity'] : 1;
      return sum + (price * quantity);
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _paymentScreenshot = File(image.path);
        });
      }
    } catch (e) {
      debugPrint("Image picker error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to pick image: ${e.toString()}")),
      );
    }
  }

  Future<void> _initiatePayment(Map<String, dynamic> app) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final amount = getTotalAmount();
    final transactionRef = 'CLOTH${DateTime.now().millisecondsSinceEpoch}';
    final encodedMerchant = Uri.encodeComponent("ClothoClock");
    final encodedNote = Uri.encodeComponent("Order #$transactionRef");

    final upiUrl = "${app['scheme']}?pa=${widget.upiId}"
        "&pn=$encodedMerchant"
        "&am=${amount.toStringAsFixed(2)}"
        "&cu=INR"
        "&tn=$encodedNote";

    try {
      debugPrint("Launching UPI: $upiUrl");
      final launched = await launchUrl(
        Uri.parse(upiUrl),
        mode: LaunchMode.externalApplication,
      );

      if (!launched) throw Exception("Failed to launch ${app['name']}");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload payment screenshot after completing payment")),
      );
    } catch (e) {
      debugPrint("Payment error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Payment failed: ${e.toString()}")),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<bool> _verifyAndProcessOrder(String txnId) async {
    if (_userId == null) return false;
    if (_paymentScreenshot == null) return false;

    setState(() => _isUploading = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("http://192.168.205.252/flutter_api/process_order.php"),
      );

      // Add fields
      request.fields['user_id'] = _userId!;
      request.fields['items'] = json.encode(widget.items);
      request.fields['amount'] = getTotalAmount().toString();
      request.fields['txn_id'] = txnId;
      request.fields['address'] = widget.address;
      request.fields['is_payment_success'] = 'true';

      // Add image file
      request.files.add(await http.MultipartFile.fromPath(
        'payment_screenshot',
        _paymentScreenshot!.path,
      ));

      final response = await request.send().timeout(const Duration(seconds: 30));
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      debugPrint("Order processing error: $e");
      return false;
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _submitPayment() async {
    if (_paymentScreenshot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload payment screenshot")),
      );
      return;
    }

    final amount = getTotalAmount();
    final transactionRef = 'CLOTH${DateTime.now().millisecondsSinceEpoch}';

    final success = await _verifyAndProcessOrder(transactionRef);
    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DeliveryStatusScreen(
            items: widget.items,
            totalAmount: amount.toInt().toString(),
            address: widget.address,
            userRole: 'Customer and Seller both',
            isPaymentCompleted: true,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment verification failed")),
      );
    }
  }

  String _generateUpiUrl() {
    final amount = getTotalAmount();
    final transactionRef = 'CLOTH${DateTime.now().millisecondsSinceEpoch}';
    final encodedMerchant = Uri.encodeComponent("ClothoClock");
    final encodedNote = Uri.encodeComponent("Order #$transactionRef");

    return "upi://pay?pa=${widget.upiId}"
        "&pn=$encodedMerchant"
        "&am=${amount.toStringAsFixed(2)}"
        "&cu=INR"
        "&tn=$encodedNote";
  }

  @override
  Widget build(BuildContext context) {
    final amount = getTotalAmount();
    final formattedTotal = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
    ).format(amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Payment',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Order Summary Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).dividerColor, width: 1),
              ),
              color: Theme.of(context).cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ORDER SUMMARY',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...widget.items.map((item) => _buildProductItem(item)),
                    const SizedBox(height: 16),
                    _buildAmountSummary(formattedTotal),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Delivery Address Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).dividerColor, width: 1),
              ),
              color: Theme.of(context).cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on_outlined,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DELIVERY ADDRESS',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.titleLarge?.color,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            widget.address,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Payment Options Title
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'PAYMENT OPTIONS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                  letterSpacing: 1,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Payment Methods
            Row(
              children: [
                // QR Code
                Expanded(
                  child: _buildPaymentOption(
                    icon: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: QrImageView(
                        data: _generateUpiUrl(),
                        version: QrVersions.auto,
                        size: 80,
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                    title: "Scan To Pay",
                  ),
                ),

                const SizedBox(width: 12),
                // UPI Payment
                Expanded(
                  child: _buildPaymentOption(
                    icon: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.account_balance,
                            size: 32,
                            color: Colors.blue,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[800]!
                                    : Colors.grey[800],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.all(2),
                              child: const Icon(
                                Icons.account_balance_wallet,
                                size: 16,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    title: "PAY VIA UPI",
                    onTap: () => _initiatePayment(_upiApps[0]),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Total Amount
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]!
                    : Colors.brown[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  Text(
                    formattedTotal,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Payment Screenshot Upload
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).dividerColor, width: 1),
              ),
              color: Theme.of(context).cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PAYMENT SCREENSHOT',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[800]!
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                            width: 1,
                          ),
                        ),
                        child: _paymentScreenshot == null
                            ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload, size: 40, color: Theme.of(context).hintColor),
                            const SizedBox(height: 8),
                            Text(
                              'Upload Payment Screenshot',
                              style: TextStyle(color: Theme.of(context).hintColor),
                            ),
                          ],
                        )
                            : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _paymentScreenshot!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    if (_paymentScreenshot != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: TextButton(
                          onPressed: _pickImage,
                          child: Text(
                            'Change Image',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isUploading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text(
                  'SUBMIT PAYMENT',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required Widget icon,
    required String title,
    double? amount,
    VoidCallback? onTap,
    TextStyle? titleStyle,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          children: [
            icon,
            const SizedBox(height: 12),
            Text(
              title,
              style: titleStyle ?? TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleMedium?.color,
              ),
            ),
            if (amount != null) ...[
              const SizedBox(height: 4),
              Text(
                '₹${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(Map<String, dynamic> item) {
    String imagePath = item['product_images'] != null &&
        item['product_images'].isNotEmpty
        ? item['product_images'][0]
        : '';
    String title = item['product_name'] ?? 'Product';
    String price = '₹${(double.tryParse(item['product_price'].toString())?.toStringAsFixed(2) ?? '0.00')}';
    int quantity = item['quantity'] ?? 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]!
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).dividerColor),
              image: imagePath.isNotEmpty
                  ? DecorationImage(
                image: NetworkImage(
                  "http://192.168.205.252/flutter_api/$imagePath",
                ),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: imagePath.isEmpty
                ? Center(
              child: Icon(Icons.image, size: 24, color: Theme.of(context).hintColor),
            )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '×$quantity',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSummary(String total) {
    return Column(
      children: [
        Divider(height: 1, color: Theme.of(context).dividerColor),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Subtotal',
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
            Text(
              total,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.titleMedium?.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Delivery',
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
            const Text(
              'FREE',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Divider(height: 1, color: Theme.of(context).dividerColor),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Amount',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleMedium?.color,
              ),
            ),
            Text(
              total,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleMedium?.color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}