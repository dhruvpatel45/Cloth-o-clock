import 'package:flutter/material.dart';

class SupportPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Check if the current theme is dark mode
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        title: Text(
          "Help And Support",
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 50),
            Center(
              child: CircleAvatar(
                radius: 100,
                backgroundColor: Colors.transparent,
                backgroundImage: AssetImage("assets/cloth.png"),
              ),
            ),
            SizedBox(height: 20),
            Container(
              margin: EdgeInsets.all(20.0),
              padding: EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode ? Colors.black45 : Colors.black12,
                    blurRadius: 10.0,
                    spreadRadius: 2.0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Welcome to the Cloth o'clock Support Center! We're here to ensure your shopping experience is smooth and enjoyable. Below are some common questions and resources to help you:",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white70 : Colors.black,
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildSectionTitle("Frequently Asked Questions (FAQs):", isDarkMode),
                  _buildFAQ("How do I place an order?", "Simply browse our categories, add items to your cart, and proceed to checkout.", isDarkMode),
                  _buildFAQ("What payment methods are accepted?", "We accept digital wallets and UPI.", isDarkMode),
                  SizedBox(height: 20),
                  _buildSectionTitle("Contact Us", isDarkMode),
                  Text(
                    "If you need further assistance, our customer support team is here to help:",
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white70 : Colors.black,
                    ),
                  ),
                  SizedBox(height: 10),
                  _buildContactInfo("Email", "clothoclock2024@gmail.com", isDarkMode),
                  _buildContactInfo("Phone", "+91 79902-49238", isDarkMode),
                  _buildContactInfo("Live Chat", "Available on our app from 9 AM to 9 PM", isDarkMode),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _buildFAQ(String question, String answer, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        children: [
          Text(
            question,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          Text(
            answer,
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.white70 : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(String title, String info, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text(
            "$title: ",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          Expanded(
            child: Text(
              info,
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white70 : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
