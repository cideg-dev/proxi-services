import 'package:flutter/material.dart';
import 'package:frontend/widgets/star_rating.dart';

class ReviewDialog extends StatefulWidget {
  final String title;
  final String? currentComment;
  final double? currentRating;
  final String submitButtonText;

  const ReviewDialog({
    super.key,
    required this.title,
    this.currentComment,
    this.currentRating,
    this.submitButtonText = 'Soumettre',
  });

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  final TextEditingController _commentController = TextEditingController();
  double _rating = 0.0;

  @override
  void initState() {
    super.initState();
    _commentController.text = widget.currentComment ?? '';
    _rating = widget.currentRating?.toDouble() ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StarRating(
            rating: _rating,
            allowHalfRating: false,
            allowEditing: true,
            onRatingChanged: (rating) {
              setState(() {
                _rating = rating;
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            decoration: const InputDecoration(
              labelText: 'Votre avis',
              border: OutlineInputBorder(),
              hintText: 'Partagez votre expérience...',
            ),
            maxLines: 4,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _rating > 0
              ? () {
                  Navigator.of(context).pop({
                    'rating': _rating,
                    'comment': _commentController.text.trim(),
                  });
                }
              : null,
          child: Text(widget.submitButtonText),
        ),
      ],
    );
  }
}