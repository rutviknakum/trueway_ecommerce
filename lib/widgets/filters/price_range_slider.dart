import 'package:flutter/material.dart';

class PriceRangeSlider extends StatelessWidget {
  final RangeValues values;
  final double min;
  final double max;
  final Function(RangeValues) onChanged;

  const PriceRangeSlider({
    Key? key,
    required this.values,
    required this.min,
    required this.max,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "₹${values.start.toInt()}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "₹${values.end.toInt()}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.orange,
              inactiveTrackColor: Colors.grey[300],
              thumbColor: Colors.orange,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              overlayColor: Colors.orange.withAlpha(50),
              rangeThumbShape: const RoundRangeSliderThumbShape(
                enabledThumbRadius: 12,
              ),
            ),
            child: RangeSlider(
              values: values,
              min: min,
              max: max,
              divisions: 100,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
