import 'package:flutter/material.dart';

class returnPolicyScreen extends StatelessWidget {
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
                      "Here’s a brief overview of our return Policy:",
                      getResponsiveFontSize(18), textColor),
                  const SizedBox(height: 15),

                  _buildSectionTitle("For Rented Products:", getResponsiveFontSize(18), textColor),
                  _buildText(
                      "  Rented products are returnable within 7 hours from the time of delivery.\n"

                     "Returns after 7 hours will not be accepted.\n"

                  "The product must be in its original condition without any damage.\n"

                     "Users can submit a return request through the application.\n"

                      "The seller will review the request and approve or reject it.\n",
                      getResponsiveFontSize(16), textColor),
                  const SizedBox(height: 15),

                  _buildSectionTitle("For Purchased Products:", getResponsiveFontSize(18), textColor),
                  _buildText(
                      "  • Purchased products can be returned within 7 days from the date of delivery.\n"

                     " Returns after 7 days will not be accepted.\n"

                    "The product must be unused and in its original packaging.\n"

                  "Users need to provide a valid reason for the return.\n"

                      "The seller will review the request and approve or reject it.\n",
                      getResponsiveFontSize(16), textColor),
                  const SizedBox(height: 15),

                  _buildSectionTitle("General Guidelines:", getResponsiveFontSize(18), textColor),
                  _buildText(
                      " Refunds or exchanges will be processed only after the seller approves the return.\n"

                      "If a return is rejected, the user will receive a reason for the decision."

                  "The platform reserves the right to modify the return policy at any time.\n",
                      getResponsiveFontSize(16), textColor),
                  const SizedBox(height: 15),

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
