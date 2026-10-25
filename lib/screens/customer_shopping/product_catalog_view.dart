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
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upgrade your everyday tech',
                      style: TextStyle(
                        color: Colors.white,
                      fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Discover devices selected for work, study and entertainment.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
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
              if (categories.isNotEmpty) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Browse by category',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _CategoryChip(
                        label: 'All',
                        selected: _category.isEmpty,
                        onSelected: () => setState(() => _category = ''),
                      ),
                      ...categories.map(
                        (category) => _CategoryChip(
                          label: category,
                          selected: _category == category,
                          onSelected: () =>
                              setState(() => _category = category),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? ShoppingMessage(
                  message: 'Could not load products. Please try again.',
                  icon: Icons.wifi_off_outlined,
                  onRetry: _load,
                )
              : visible.isEmpty
              ? ShoppingMessage(
                  message: _query.isEmpty && _category.isEmpty
                      ? 'There are no products to show yet.'
                      : 'No products match your search. Try another name or category.',
                  icon: Icons.search_off_rounded,
                  onRetry: _load,
                  retryLabel: 'Refresh products',
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                    itemCount: visible.length,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 280,
                          mainAxisExtent: 270,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                    itemBuilder: (context, index) {
                      final product = visible[index];
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        elevation: 0,
                        child: InkWell(
                          onTap: () => _details(product),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Center(
                                    child: ShoppingImage(
                                      url: widget.api.imageUrl(
                                        product.imageUrl,
                                      ),
                                      size: 138,
                                    ),
                                  ),
                                ),
                                Text(
                                  product.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  product.category.isEmpty
                                      ? product.brand
                                      : product.category,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      fontSize: 13,
                                    ),
                                ),
                                if (product.fromPrice != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'From ${shoppingMoney(product.fromPrice!)}',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
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

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      labelStyle: TextStyle(
        color: selected ? Theme.of(context).colorScheme.primary : null,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    ),
  );
}
