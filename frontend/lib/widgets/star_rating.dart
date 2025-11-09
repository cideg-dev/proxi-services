import 'package:flutter/material.dart';

class StarRating extends StatefulWidget {
  final double rating;
  final int maxRating;
  final bool allowHalfRating;
  final bool allowEditing;
  final ValueChanged<double>? onRatingChanged;

  const StarRating({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.allowHalfRating = false,
    this.allowEditing = false,
    this.onRatingChanged,
  });

  @override
  State<StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating> {
  late double _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.rating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.maxRating, (index) {
        final starIndex = index + 1;
        final isFilled = starIndex <= _rating;
        final isHalf = widget.allowHalfRating && 
                      starIndex > _rating && 
                      starIndex - 0.5 <= _rating;

        return GestureDetector(
          onTap: widget.allowEditing 
              ? () {
                  setState(() {
                    _rating = starIndex.toDouble();
                  });
                  if (widget.onRatingChanged != null) {
                    widget.onRatingChanged!(_rating);
                  }
                }
              : null,
          child: Icon(
            isFilled ? Icons.star : (isHalf ? Icons.star_half : Icons.star_border),
            color: isFilled || isHalf ? Colors.amber : Colors.grey,
            size: 24,
          ),
        );
      }),
    );
  }
}