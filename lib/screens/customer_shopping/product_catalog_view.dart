//Tiêu Gia Huy
import 'package:flutter/material.dart';

import '../../models/customer_shopping.dart';
import '../../services/customer_shopping_api.dart';
import '../../services/review_api.dart';
import '../customer_product_detail_screen.dart';
import 'shopping_widgets.dart';

class ProductCatalogView extends StatefulWidget {
  const ProductCatalogView({super.key, required this.api, this.customerId = 0});
  final CustomerShoppingApi api;
  final int customerId;
  @override
  State<ProductCatalogView> createState() => _ProductCatalogViewState();
}

class _ProductCatalogViewState extends State<ProductCatalogView> {
  List<ShopProduct> _products = [];
  bool _loading = true;
  String? _error;
  String _query = '', _category = '';
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
      final products = await widget.api.getProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        if (!products.any((p) => p.category == _category)) _category = '';
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _details(ShopProduct product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerProductDetailScreen(
          product: product,
          api: widget.api,
          reviewApi: ReviewApi(baseUrl: widget.api.baseUrl),
          customerId: widget.customerId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        _products
            .map((p) => p.category)
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final visible = _products
        .where(
          (p) =>
              (_category.isEmpty || p.category == _category) &&
              '${p.name} ${p.brand}'.toLowerCase().contains(
                _query.trim().toLowerCase(),
              ),
        )
        .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) => setState(() => _query = value),
                      decoration: const InputDecoration(
                        labelText: 'Search products',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _loading ? null : _load,
                    tooltip: 'Refresh products',
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey(_category),
                initialValue: _category,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('All categories'),
                  ),
                  ...categories.map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(c, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _category = value ?? ''),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? ShoppingMessage(message: _error!, onRetry: _load)
              : visible.isEmpty
              ? ShoppingMessage(message: 'No products found.', onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final product = visible[index];
                      return InkWell(
                        onTap: () => _details(product),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              ShoppingImage(
                                url: widget.api.imageUrl(product.imageUrl),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    Text(
                                      '${product.brand} / ${product.category}',
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      product.fromPrice == null
                                          ? 'No variants available'
                                          : 'From ${shoppingMoney(product.fromPrice!)}',
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
