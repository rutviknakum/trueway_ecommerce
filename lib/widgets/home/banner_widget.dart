import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BannerWidget extends StatelessWidget {
  final String bannerUrl;

  const BannerWidget({Key? key, required this.bannerUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: bannerUrl,
          fit: BoxFit.cover,
          placeholder:
              (context, url) => Container(
                color: Colors.grey[200],
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                  ),
                ),
              ),
          errorWidget:
              (context, url, error) => Container(
                color: Colors.grey[200],
                child: Icon(Icons.error, size: 40, color: Colors.grey[400]),
              ),
        ),
      ),
    );
  }
}
