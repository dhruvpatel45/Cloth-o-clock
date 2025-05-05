import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double textFontSize = screenWidth * 0.030;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? Colors.grey[900] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final cardColor = isDarkMode ? Colors.grey[800] : Colors.white;
    final appBarColor = isDarkMode ? Colors.grey[850] : Colors.white;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        title: Text("About Us", style: TextStyle(color: textColor)),
        iconTheme: IconThemeData(color: textColor),
      ),
      backgroundColor: bgColor,
      body: Container(
        color: bgColor,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              height: screenHeight * 0.85,
              child: Card(
                color: cardColor,
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              "assets/group_image.jpg",
                              width: screenWidth * 0.8,
                              height: screenWidth * 0.5,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildText(
                              "At Cloth o’clock, we’re redefining fashion by making it accessible, sustainable, and hassle-free. Born from the idea of sharing instead of owning, our platform lets you enjoy the latest styles without the waste or high costs of traditional shopping.",
                              textFontSize, textColor),
                          _buildText(
                              "We believe that fashion should be an experience, not just a purchase. Our carefully curated collection allows you to stay ahead of trends while making mindful choices for the planet. Whether it's a special occasion or everyday wear, we ensure quality, variety, and affordability at your fingertips.",
                              textFontSize, textColor),
                          _buildText(
                              "By embracing rental, we help reduce fashion waste and create a greener planet, all while giving you the freedom to explore endless wardrobe options. Our commitment to circular fashion means less textile waste, fewer carbon emissions, and a smarter way to enjoy the latest trends.",
                              textFontSize, textColor),
                          _buildText(
                              "We take pride in fostering a community that values sustainability without compromising on style. Our platform connects fashion lovers with an innovative way to express themselves while contributing to a healthier environment.",
                              textFontSize, textColor),
                          _buildText(
                              "Join our community of trendsetters and changemakers — because fashion should be fun, affordable, and kind to the planet. Together, let's redefine the way we shop, dress, and make a difference, one outfit at a time.",
                              textFontSize, textColor),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildText(String text, double fontSize, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: TextStyle(fontSize: fontSize, height: 1.5, color: textColor)),
    );
  }
}
