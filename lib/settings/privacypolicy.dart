import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    // Dark mode check
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? Colors.grey[900] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final cardColor = isDarkMode ? Colors.grey[800] : Colors.white;

    // Function to scale font size based on screen width
    double getResponsiveFontSize(double baseSize) {
      return (screenWidth / 400) * baseSize;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: bgColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        title: Text(
          'Privacy Policy',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: getResponsiveFontSize(20),
          ),
        ),
      ),
      backgroundColor: bgColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          color: cardColor,
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildText(
                      "At Cloth o’clock, we respect your privacy and are committed to protecting your personal data.",
                      getResponsiveFontSize(20), textColor),
                  const SizedBox(height: 10),
                  _buildText(
                      "Here’s a brief overview of our Privacy Policy:",
                      getResponsiveFontSize(18), textColor),
                  const SizedBox(height: 15),

                  _buildSectionTitle("1. What We Collect", getResponsiveFontSize(18), textColor),
                  _buildText(
                      "  • Personal Information: Name, email, phone number, address, and payment details.\n"
                          "  • Usage Data: App interactions, browsing history, and device information.\n"
                          "  • Transaction Details: Orders, rentals, and purchases.",
                      getResponsiveFontSize(16), textColor),
                  const SizedBox(height: 15),

                  _buildSectionTitle("2. How We Use Your Information", getResponsiveFontSize(18), textColor),
                  _buildText(
                      "  • To process orders, payments, and deliveries.\n"
                          "  • To personalize your app experience and send updates or offers (with consent).\n"
                          "  • For legal compliance and improving our services.",
                      getResponsiveFontSize(16), textColor),
                  const SizedBox(height: 15),

                  _buildSectionTitle("3. Sharing Your Information", getResponsiveFontSize(18), textColor),
                  _buildText(
                      " We only share your data with trusted service providers (e.g., for payments or delivery), "
                          "legal authorities (if required), or as part of business transactions (e.g., mergers).",
                      getResponsiveFontSize(16), textColor),
                  const SizedBox(height: 15),

                  _buildSectionTitle("4. Your Rights", getResponsiveFontSize(18), textColor),
                  _buildText(
                      " You can access, correct, delete, or restrict your data and opt out of marketing communications.",
                      getResponsiveFontSize(15), textColor),
                  const SizedBox(height: 17),

                  _buildSectionTitle("5. Security", getResponsiveFontSize(18), textColor),
                  _buildText(
                      " We use encryption and secure storage to protect your data.",
                      getResponsiveFontSize(16), textColor),
                  const SizedBox(height: 20),

                  _buildText(
                      "By using this app, you agree to our Privacy Policy. If you have any questions, feel free to contact us.\n"
                          "Email: Clothoclock2024@gmail.com",
                      getResponsiveFontSize(16), textColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildText(String text, double fontSize, Color color) {
    return Text(
      text,
      style: TextStyle(fontSize: fontSize, color: color, height: 1.5),
    );
  }

  Widget _buildSectionTitle(String text, double fontSize, Color color) {
    return Text(
      text,
      style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: color),
    );
  }
}
