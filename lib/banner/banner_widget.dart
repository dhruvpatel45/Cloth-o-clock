import 'package:flutter/material.dart';

class BannerWidget extends StatelessWidget {
  final int index;

  BannerWidget(this.index);

  final List<String> bannerImages = [
    'assets/banner1.jpg',
    'assets/banner2.jpg',
    'assets/banner4.jpg',
    'assets/banner5.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(bannerImages[index]),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
