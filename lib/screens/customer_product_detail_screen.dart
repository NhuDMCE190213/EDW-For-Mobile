import 'package:flutter/material.dart';

import '../models/customer_shopping.dart';
import '../models/review.dart';
import '../services/customer_shopping_api.dart';
import '../services/review_api.dart';
import 'customer_shopping/shopping_widgets.dart';

class CustomerProductDetailScreen extends StatefulWidget {
  const CustomerProductDetailScreen({
    super.key,
    required this.product,
    required this.api,
    required this.reviewApi,
  });

  final ShopProduct product;
  final CustomerShoppingApi api;
  final ReviewApi reviewApi;

  @override
  State<CustomerProductDetailScreen> createState() =>
      _CustomerProductDetailScreenState();
}

class _CustomerProductDetailScreenState
    extends State<CustomerProductDetailScreen> {
  late ShopProduct _product = widget.product;
  List<ReviewItem> _reviews = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.api.getProduct(widget.product.id),
        widget.reviewApi.getProductReviews(widget.product.id),
      ]);
      if (!mounted) return;
      setState(() {
        _product = results[0] as ShopProduct;
        _reviews = results[1] as List<ReviewItem>;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ShoppingMessage(message: _error!, onRetry: _load)
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Center(
                    child: ShoppingImage(
                      url: widget.api.imageUrl(_product.imageUrl),
                      size: 220,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _product.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text('${_product.brand} • ${_product.category}'),
                  const SizedBox(height: 20),
                  Text(
                    'Available variants',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (_product.variants.isEmpty)
                    const Text('No variants available.')
                  else
                    ..._product.variants.map(
                      (variant) => Card(
                        child: ListTile(
                          title: Text('${variant.sku} • ${variant.color}'),
                          subtitle: Text(
                            '${variant.configuration}\n'
                            '${variant.stock > 0 ? 'In stock: ${variant.stock}' : 'Out of stock'}',
                          ),
                          isThreeLine: true,
                          trailing: Text(shoppingMoney(variant.price)),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    'Customer reviews',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (_reviews.isEmpty)
                    const Text('No reviews for this product yet.')
                  else
                    ..._reviews.map(
                      (review) => Card(
                        child: ListTile(
                          title: Row(
                            children: [
                              ...List.generate(
                                5,
                                (index) => Icon(
                                  index < review.rating
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 18,
                                  color: Colors.amber.shade700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(review.customerName)),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(review.comment),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
