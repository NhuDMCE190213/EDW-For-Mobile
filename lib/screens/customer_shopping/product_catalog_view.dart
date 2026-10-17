//Tiêu Gia Huy
import 'package:flutter/material.dart';

import '../../models/customer_shopping.dart';
import '../../services/customer_shopping_api.dart';
import 'shopping_widgets.dart';

class ProductCatalogView extends StatefulWidget {
  const ProductCatalogView({super.key, required this.api});
  final CustomerShoppingApi api;
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
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: ShoppingImage(
                    url: widget.api.imageUrl(product.imageUrl),
                    size: 160,
                  ),
                ),
                Text('${product.brand} / ${product.category}'),
                if (product.variants.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text('No variants available.'),
                  ),
                for (final variant in product.variants) ...[
                  const Divider(height: 24),
                  Text(
                    '${variant.sku} - ${variant.color}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(variant.configuration),
                  Text(shoppingMoney(variant.price)),
                  Text(
                    variant.stock > 0
                        ? 'In stock: ${variant.stock}'
                        : 'Out of stock',
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
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
