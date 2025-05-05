import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CategoryWidget extends StatelessWidget {
  final String name;
  final String imageUrl;

  const CategoryWidget(this.name, this.imageUrl, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundImage: CachedNetworkImageProvider(imageUrl),
        ),
        SizedBox(height: 8),
        Text(
          name,
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}