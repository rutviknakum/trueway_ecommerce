import 'package:flutter/material.dart';

class FilterSection extends StatelessWidget {
  final String title;
  final Widget child;

  const FilterSection({Key? key, required this.title, required this.child})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.grey[300]!),
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(Icons.expand_more, color: Colors.grey[600]),
            ],
          ),
        ),
        child,
      ],
    );
  }
}
