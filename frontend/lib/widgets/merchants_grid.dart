import 'package:flutter/material.dart';
import 'package:frontend/services/merchant_service.dart';

class MerchantsGrid extends StatefulWidget {
  final int limit;
  final String? category;
  
  const MerchantsGrid({super.key, this.limit = 6, this.category});

  @override
  State<MerchantsGrid> createState() => _MerchantsGridState();
}

class _MerchantsGridState extends State<MerchantsGrid> {
  final MerchantService _merchantService = MerchantService();
  List<dynamic> _merchants = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadMerchants();
  }

  Future<void> _loadMerchants() async {
    try {
      List<dynamic> merchants;
      
      if (widget.category != null) {
        merchants = await _merchantService.getMerchantByCategory(widget.category!);
      } else {
        merchants = await _merchantService.getMerchants();
      }
      
      // Limiter le nombre de résultats
      if (widget.limit > 0 && merchants.length > widget.limit) {
        merchants = merchants.take(widget.limit).toList();
      }
      
      setState(() {
        _merchants = merchants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des commerçants: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(_errorMessage),
      );
    }

    if (_merchants.isEmpty) {
      return const Center(
        child: Text('Aucun commerçant trouvé.'),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 12.0,
        childAspectRatio: 0.8,
      ),
      itemCount: _merchants.length,
      itemBuilder: (context, index) {
        final merchant = _merchants[index];
        return _buildMerchantCard(merchant);
      },
    );
  }

  Widget _buildMerchantCard(dynamic merchant) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image du commerçant ou de ses produits
          Expanded(
            flex: 2,
            child: Container(
              color: theme.colorScheme.surfaceVariant,
              child: const Icon(Icons.store, size: 40),
            ),
          ),
          // Informations sur le commerçant
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    merchant['name'] ?? merchant['email'] ?? 'Commerçant',
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    merchant['business_type'] ?? 'Type de commerce',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        (merchant['rating'] ?? 'N/A').toString(),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}