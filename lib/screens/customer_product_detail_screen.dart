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
    required this.customerId,
  });

  final ShopProduct product;
  final CustomerShoppingApi api;
  final ReviewApi reviewApi;
  final int customerId;

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
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _addToCart(ShopVariant variant) async {
    if (variant.stock < 1 || _adding) return;
    final quantity = await showDialog<int>(
      context: context,
      builder: (context) => _QuantityDialog(max: variant.stock),
    );
    if (!mounted || quantity == null) return;
    setState(() => _adding = true);
    try {
      await widget.api.addToCart(
        customerId: widget.customerId,
        productVariantId: variant.id,
        quantity: quantity,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Product added to cart.')));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
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
                  const SizedBox(height: 14),
                  const Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: Icon(Icons.verified_outlined, size: 18),
                        label: Text('Genuine products'),
                      ),
                      Chip(
                        avatar: Icon(Icons.local_shipping_outlined, size: 18),
                        label: Text('Fast delivery'),
                      ),
                      Chip(
                        avatar: Icon(Icons.support_agent_outlined, size: 18),
                        label: Text('Expert support'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose the configuration that fits your needs. '
                    'Every device is checked before shipping and supported by EDW.',
                  ),
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
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(shoppingMoney(variant.price)),
                              TextButton(
                                onPressed: variant.stock > 0 && !_adding
                                    ? () => _addToCart(variant)
                                    : null,
                                child: const Text('Add to cart'),
                              ),
                            ],
                          ),
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

class _QuantityDialog extends StatefulWidget {
  const _QuantityDialog({required this.max});
  final int max;

  @override
  State<_QuantityDialog> createState() => _QuantityDialogState();
}

class _QuantityDialogState extends State<_QuantityDialog> {
  final _controller = TextEditingController(text: '1');
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final quantity = int.tryParse(_controller.text.trim());
    if (quantity == null || quantity < 1 || quantity > widget.max) {
      setState(() => _error = 'Enter a quantity from 1 to ${widget.max}.');
      return;
    }
    Navigator.pop(context, quantity);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add to cart'),
    content: TextField(
      controller: _controller,
      autofocus: true,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Quantity',
        helperText: 'Available: ${widget.max}',
        errorText: _error,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Add')),
    ],
  );
}
