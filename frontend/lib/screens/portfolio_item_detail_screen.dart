import 'package:flutter/material.dart';
import 'dart:ui';

class PortfolioItemDetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;

  const PortfolioItemDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final String heroTag = 'portfolio-image-${item['id']}';
    final String name = item['name'] ?? 'Projet';
    final String description = item['description'] ?? item['caption'] ?? '';
    final dynamic price = item['price'];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background blurred image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(item['image_url']),
                fit: BoxFit.cover,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
              child: Container(
                color: Colors.black.withOpacity(0.6),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Image with Hero animation
                  Hero(
                    tag: heroTag,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      child: Image.network(
                        item['image_url'],
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const AspectRatio(
                          aspectRatio: 1,
                          child: Center(
                            child: Icon(Icons.broken_image, color: Colors.white, size: 60),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Name
                  Text(
                    name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),

                  // Price
                  if (price != null && price.toString().isNotEmpty)
                    Text(
                      '$price CFA',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.85),
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),
          ),
          // Back button
          Positioned(
            top: 40,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.5),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
