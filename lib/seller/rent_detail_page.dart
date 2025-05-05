import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hello/seller/home_page.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'availability.dart';
import 'package:hello/wishlist/like_page.dart' as Rent_detail_like;
import 'cart_page.dart' as Rent_detail_cart;
import 'dart:math';

class RentDetailPage extends StatefulWidget {
  final int productId;

  const RentDetailPage({Key? key, required this.productId}) : super(key: key);

  @override
  _RentDetailPageState createState() => _RentDetailPageState();
}

class _RentDetailPageState extends State<RentDetailPage> {
  Map<String, dynamic>? productData;
  bool isLoading = true;
  DateTime? startDate;
  DateTime? endDate;
  bool showMoreFeedback = false;
  final TextEditingController _feedbackController = TextEditingController();
  int _feedbackRating = 0;
  int _currentImageIndex = 0;
  List<dynamic> feedbackList = [];

  /*final List<Map<String, dynamic>> feedbackList = [
    {'rating': 4, 'comment': 'Great product! Fits perfectly.'},
    {'rating': 5, 'comment': 'Excellent quality and fast delivery.'},
    {'rating': 3, 'comment': 'Good, but the fabric could be better.'},
  ];*/

  @override
  void initState() {
    super.initState();
    fetchProductDetails();
    _fetchFeedback();
  }

  Future<void> fetchProductDetails() async {
    final url = Uri.parse("http://192.168.205.252/flutter_api/get_rent.php?product_id=${widget.productId}");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['success'] == true && decoded['products'] != null && decoded['products'].isNotEmpty) {
          setState(() {
            productData = decoded['products'][0];
            if (productData!['product_images'] is String) {
              productData!['product_images'] = productData!['product_images'].split(',');
            }
            isLoading = false;
          });
        } else {
          setState(() {
            productData = null;
            isLoading = false;
          });
        }
      } else {
        print("Failed to fetch product: ${response.body}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching product: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> likeProduct() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString('userId') ?? "0";

    if (userId == "0") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to like products')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("http://192.168.205.252/flutter_api/like_product.php"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "user_id": userId,
          "product_id": widget.productId.toString(),
          "category": "rent",
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'])),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to like product')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: ${e.toString()}')),
      );
    }
  }

  void _showDatePicker(BuildContext context) async {
    DateTime? selectedStartDate;
    DateTime? selectedEndDate;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              contentPadding: const EdgeInsets.all(20),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Select Rental Dates (Max 7 Days)",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.4,
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: CalendarDatePicker(
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2023),
                      lastDate: DateTime(2100),
                      onDateChanged: (selectedDate) {
                        setDialogState(() {
                          selectedStartDate ??= selectedDate;
                          if (selectedDate.difference(selectedStartDate!).inDays <= 7 &&
                              (selectedDate.isAfter(selectedStartDate!) || selectedDate.isAtSameMomentAs(selectedStartDate!))) {
                            selectedEndDate = selectedDate;
                          } else if (selectedDate.isBefore(selectedStartDate!)) {
                            selectedStartDate = selectedDate;
                            selectedEndDate = null;
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Maximum rental duration is 7 days.')),
                            );
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (selectedStartDate != null)
                    Text(
                      "Start Date: ${DateFormat('dd MMM yyyy').format(selectedStartDate!)}",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  if (selectedEndDate != null)
                    Text(
                      "End Date: ${DateFormat('dd MMM yyyy').format(selectedEndDate!)}",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () {
                      if (selectedStartDate != null && selectedEndDate != null) {
                        setState(() {
                          startDate = selectedStartDate;
                          endDate = selectedEndDate;
                        });
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select both start and end dates.')),
                        );
                      }
                    },
                    child: const Text("Schedule", style: TextStyle(fontSize: 20)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _fetchFeedback() async {
    try {
      // Update the URL to send the correct product type ("sell")
      final response = await http.get(
        Uri.parse("http://192.168.205.252/flutter_api/get_product_feedback.php?product_id=${widget.productId}&product_type=rent"),
      );

      if (response.statusCode == 200) {
        // Decode the response body into a list of feedback
        final data = json.decode(response.body);

        setState(() {
          // Store the feedback data into feedbackList
          feedbackList = List<Map<String, dynamic>>.from(data.map((feedback) => feedback as Map<String, dynamic>));
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch feedback: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _submitFeedback() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString('userId') ?? "0";

    if (userId == "0") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to submit feedbacks.')),
      );
      return;
    }
    if (_feedbackController.text.isNotEmpty && _feedbackRating > 0) {
      try {
        /*final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('userId') ?? "0";  // Get userId from shared preferences

        // Prepare the data to send to the backend*/
        final response = await http.post(
          Uri.parse("http://192.168.205.252/flutter_api/submit_product_feedback.php"),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            "product_id": widget.productId.toString(),
            "user_id": userId,
            "feedback": _feedbackController.text,
            "rating": _feedbackRating,
            "product_type": "rent",
          }),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'success') {
            setState(() {
              _feedbackController.clear();
              _feedbackRating = 0;
            });
            _fetchFeedback();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(data['message'] ?? 'Failed to submit feedback')),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildRatingStars(int rating) {
    return Row(
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 30,
          ),
          onPressed: () {
            setState(() {
              _feedbackRating = index + 1;
            });
          },
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.brown[50],
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.brown[50],
        elevation: 0,
        title: Row(
          children: [
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search',
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: isDarkMode ? Colors.white : Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              icon: Icon(Icons.favorite_border, color: isDarkMode ? Colors.white : Colors.black),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) =>  Rent_detail_like.LikePage()));
              },
            ),
            IconButton(
              icon: Icon(Icons.shopping_bag_outlined, color: isDarkMode ? Colors.white : Colors.black),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) =>  Rent_detail_cart.ShoppingBag()));
              },
            ),
          ],
        ),
      ),
      body: productData == null || isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            if (productData!['product_images'] != null && (productData!['product_images'] as List).isNotEmpty)
              Column(
                children: [
                  Container(
                    height: 300,
                    child: PhotoViewGallery.builder(
                      itemCount: productData!['product_images'].length,
                      builder: (context, index) {
                        return PhotoViewGalleryPageOptions(
                          imageProvider: NetworkImage('http://192.168.205.252/flutter_api/${productData!['product_images'][index]}'),
                          minScale: PhotoViewComputedScale.contained,
                          maxScale: PhotoViewComputedScale.covered,
                        );
                      },
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      scrollPhysics: const BouncingScrollPhysics(),
                      backgroundDecoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[900] : Colors.brown[50],
                      ),
                      pageController: PageController(initialPage: _currentImageIndex),
                    ),
                  ),
                  if (productData!['product_images'].length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(productData!['product_images'].length, (index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImageIndex == index
                                  ? Colors.blue
                                  : Colors.grey,
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productData!['product_name'] ?? 'No Title',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text("Price: ", style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white : Colors.black)),
                      Text(
                        '₹${productData!['product_price']} / day',
                        style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white : Colors.black),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '| Qty: ${productData!['quantity'] ?? 'N/A'}',
                        style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white : Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (productData!['product_size'] != '-' && productData!['product_size'] != null)
                    Row(
                      children: [
                        Text('Size: ', style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white : Colors.black)),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            border: Border.all(color: isDarkMode ? Colors.white : Colors.black),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            productData!['product_size'],
                            style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white : Colors.black),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text('Select Date: ', style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white : Colors.black)),
                      GestureDetector(
                        onTap: () => _showDatePicker(context),
                        child: Icon(FontAwesomeIcons.solidCalendarDays, size: 24, color: isDarkMode ? Colors.white : Colors.black),
                      ),
                      const SizedBox(width: 10),
                      if (startDate != null && endDate != null)
                        Text(
                          "${DateFormat('dd MMM').format(startDate!)} - ${DateFormat('dd MMM').format(endDate!)}",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Product Details', style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white : Colors.black)),
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          productData!['product_desc'] != null
                              ? '- ${productData!['product_desc']}'
                              : '- No description available.',
                          style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white : Colors.black),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDarkMode ? Colors.white : Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: likeProduct,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(FontAwesomeIcons.solidHeart, color: isDarkMode ? Colors.black : Colors.white),
                              const SizedBox(width: 5),
                              Text('Like', style: TextStyle(color: isDarkMode ? Colors.black : Colors.white)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDarkMode ? Colors.white : Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: () async {
                            if (startDate == null || endDate == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please select both start and end dates.')),
                              );
                              return;
                            }

                            try {
                              final prefs = await SharedPreferences.getInstance();
                              final userId = prefs.getString('userId') ?? "0";

                              final response = await http.post(
                                Uri.parse("http://192.168.205.252/flutter_api/submit_rent_request.php"),
                                headers: {'Content-Type': 'application/json'},
                                body: json.encode({
                                  "product_id": widget.productId.toString(),
                                  "renter_id": userId,
                                  "start_date": startDate!.toIso8601String(),
                                  "end_date": endDate!.toIso8601String(),
                                }),
                              );

                              if (response.statusCode == 200) {
                                final data = json.decode(response.body);
                                if (data['status'] == 'success') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SellerHomePage(
                                      ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(data['message'] ?? 'Request failed')),
                                  );
                                }
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: ${e.toString()}')),
                              );
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                FontAwesomeIcons.calendarCheck,
                                color: isDarkMode ? Colors.black : Colors.white,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Check Availability',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.black : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Customer Feedback', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
                  const SizedBox(height: 10),
                  _buildRatingStars(_feedbackRating),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _feedbackController,
                    decoration: InputDecoration(
                      hintText: 'Write your feedback...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: isDarkMode ? Colors.white : Colors.black),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.send, color: isDarkMode ? Colors.white : Colors.black),
                        onPressed: _submitFeedback,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    children: feedbackList.isEmpty
                        ? [Text('No feedback yet.', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black))]
                        : feedbackList
                        .sublist(0, showMoreFeedback ? feedbackList.length : min(2, feedbackList.length))
                        .map((feedback) {
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(
                            feedback['feedback'],
                            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Rating stars
                              Row(
                                children: List.generate(5, (index) {
                                  return Icon(
                                    index < (feedback['rating'] ?? 0)
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                    size: 20,
                                  );
                                }),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Rating: ${feedback['rating']}/5',
                                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                              ),
                              Text(
                                'By: ${feedback['full_name']}',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white70 : Colors.black87,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (feedbackList.length > 2)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          showMoreFeedback = !showMoreFeedback;
                        });
                      },
                      child: Text(showMoreFeedback ? 'Show Less' : 'Show More', style: const TextStyle(color: Colors.blue)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}