import 'package:flutter/material.dart';

class SellHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width; // Get screen width

    // Define responsive font sizes
    double titleFontSize = screenWidth * 0.05; // "Last month" text
    double orderIdFontSize = screenWidth * 0.04; // Order ID
    double priceFontSize = screenWidth * 0.040; // Price
    double nameFontSize = screenWidth * 0.038; // Customer Name

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text("Orders"),
      ),
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Scrollbar(
            thumbVisibility: true, // Makes the scrollbar always visible
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10), // Adds space from the top
                  Text(
                    "Last month",
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10), // Space between text and first image

                  // Order Item 1
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset('assets/image 56.png', width: 130, height: 180),
                      SizedBox(width: 10), // Space between image and text
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Order ID - D395428",
                            style: TextStyle(fontSize: orderIdFontSize, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "₹8,500",
                            style: TextStyle(fontSize: priceFontSize, fontWeight: FontWeight.w600, color: Colors.black),
                          ),
                          Text(
                            "Zeel Patel",
                            style: TextStyle(fontSize: nameFontSize, fontWeight: FontWeight.normal),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 10),

                  // Order Item 2
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset('assets/tealhoodie.png', width: 130, height: 180),
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Order ID - F395025",
                            style: TextStyle(fontSize: orderIdFontSize, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "₹1,250",
                            style: TextStyle(fontSize: priceFontSize, fontWeight: FontWeight.w600, color: Colors.black),
                          ),
                          Text(
                            "Tanvi Kakkad",
                            style: TextStyle(fontSize: nameFontSize, fontWeight: FontWeight.normal),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 10),

                  // Order Item 3
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset('assets/image 65.png', width: 130, height: 180),
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Order ID - H017875",
                            style: TextStyle(fontSize: orderIdFontSize, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "₹4,500",
                            style: TextStyle(fontSize: priceFontSize, fontWeight: FontWeight.w600, color: Colors.black),
                          ),
                          Text(
                            "Hanisha Jain",
                            style: TextStyle(fontSize: nameFontSize, fontWeight: FontWeight.normal),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 10),

                  // Order Item 4
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset('assets/image 66.png', width: 130, height: 180),
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Order ID - F569013",
                            style: TextStyle(fontSize: orderIdFontSize, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "₹1,000",
                            style: TextStyle(fontSize: priceFontSize, fontWeight: FontWeight.w600, color: Colors.black),
                          ),
                          Text(
                            "Aryan Parikh",
                            style: TextStyle(fontSize: nameFontSize, fontWeight: FontWeight.normal),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
