import 'package:flutter/material.dart';
import 'package:frontend/widgets/star_rating.dart';
import 'package:intl/intl.dart';

class ReviewsList extends StatelessWidget {
  final List<dynamic> reviews;
  final bool showAddReviewButton;
  final VoidCallback? onAddReviewPressed;

  const ReviewsList({
    super.key,
    required this.reviews,
    this.showAddReviewButton = false,
    this.onAddReviewPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showAddReviewButton && onAddReviewPressed != null)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: onAddReviewPressed,
              icon: const Icon(Icons.add_comment),
              label: const Text('Ajouter un avis'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ...reviews.map((review) => _buildReviewCard(context, review)).toList(),
        if (reviews.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Aucun avis pour le moment'),
          ),
      ],
    );
  }

  Widget _buildReviewCard(BuildContext context, dynamic review) {
    final theme = Theme.of(context);
    final DateTime createdAt = DateTime.parse(review['createdAt'] ?? review['created_at'] ?? DateTime.now().toIso8601String());
    final String formattedDate = DateFormat('dd/MM/yyyy').format(createdAt);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                  child: Icon(
                    Icons.person,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review['author'] ?? review['user']?['name'] ?? 'Utilisateur',
                        style: theme.textTheme.titleMedium,
                      ),
                      Row(
                        children: [
                          StarRating(
                            rating: (review['rating'] ?? 0).toDouble(),
                            allowHalfRating: true,
                            allowEditing: false,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${review['rating'] ?? 0}/5',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  formattedDate,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              review['comment'] ?? review['content'] ?? 'Aucun commentaire',
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}