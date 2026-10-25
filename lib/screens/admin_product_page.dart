import 'package:flutter/material.dart';

import '../core/product_image.dart';
import '../models/admin_catalog.dart';
import '../services/admin_catalog_api.dart';

/// Admin product management (list / search / filter / add / edit / delete).
/// Reuses AdminCatalogApi + AdminProduct + ProductInput (no API/model changes).
class AdminProductPage extends StatefulWidget {
  const AdminProductPage({super.key, required this.api, this.baseUrl});

  final AdminCatalogApi api;
  final String? baseUrl;

  @override
  State<AdminProductPage> createState() => AdminProductPageState();
}

class AdminProductPageState extends State<AdminProductPage> {
  final _search = TextEditingController();
  List<AdminProduct> _products = [];
  List<AdminCategory> _categories = [];
  int? _categoryFilter;
  bool _showDeleted = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.api.getProducts(),
        widget.api.getCategories(),
      ]);
      if (!mounted) return;
      setState(() {
        _products = results[0] as List<AdminProduct>;
        _categories = results[1] as List<AdminCategory>;
        // Drop a stale filter so the dropdown value always exists.
        if (_categoryFilter != null &&
            !_categories.any((c) => c.id == _categoryFilter)) {
          _categoryFilter = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<AdminCategory> get _activeCategories =>
      _categories.where((c) => !c.isDeleted).toList();

  List<AdminProduct> get _filtered {
    final q = _search.text.trim().toLowerCase();
    return _products.where((p) {
      if (!_showDeleted && p.isDeleted) return false;
      if (_categoryFilter != null && p.categoryId != _categoryFilter) {
        return false;
      }
      return q.isEmpty ||
          p.productName.toLowerCase().contains(q) ||
          p.brand.toLowerCase().contains(q);
    }).toList()
      ..sort(
        (a, b) =>
            a.productName.toLowerCase().compareTo(b.productName.toLowerCase()),
      );
  }

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _openEditor([AdminProduct? product]) async {
    final categories = _activeCategories;
    if (categories.isEmpty) {
      _toast('Create a category first.', error: true);
      return;
    }
    final name = TextEditingController(text: product?.productName ?? '');
    final brand = TextEditingController(text: product?.brand ?? '');
    final image = TextEditingController(text: product?.imageUrl ?? '');
    final formKey = GlobalKey<FormState>();
    int? categoryId = product?.categoryId;
    // Keep the product's current category selectable even if it was deleted,
    // and never pass a value that is missing from the items.
    final options = <int, String>{
      for (final c in categories) c.id: c.name,
    };
    if (categoryId != null && !options.containsKey(categoryId)) {
      options[categoryId] = product?.categoryName.isNotEmpty == true
          ? '${product!.categoryName} (deleted)'
          : 'Category #$categoryId';
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(product == null ? 'Add product' : 'Edit product'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: name,
                      decoration:
                          const InputDecoration(labelText: 'Product name *'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Product name is required'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: brand,
                      decoration: const InputDecoration(labelText: 'Brand *'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Brand is required'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: categoryId,
                      isExpanded: true,
                      decoration:
                          const InputDecoration(labelText: 'Category *'),
                      items: [
                        for (final e in options.entries)
                          DropdownMenuItem<int>(
                            value: e.key,
                            child: Text(e.value,
                                overflow: TextOverflow.ellipsis),
                          ),
                      ],
                      validator: (v) => v == null ? 'Select a category' : null,
                      onChanged: (v) => setLocal(() => categoryId = v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: image,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Image URL',
                        hintText: 'https://...',
                      ),
                      onChanged: (_) => setLocal(() {}),
                    ),
                    const SizedBox(height: 12),
                    ProductImage(
                      urls: [image.text],
                      baseUrl: widget.baseUrl,
                      size: 96,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    final input = ProductInput(
      productId: product?.productId,
      productName: name.text.trim(),
      brand: brand.text.trim(),
      categoryId: categoryId ?? 0,
      imageUrl: image.text.trim().isEmpty ? null : image.text.trim(),
    );
    name.dispose();
    brand.dispose();
    image.dispose();
    if (saved != true) return;

    try {
      if (product == null) {
        await widget.api.createProduct(input);
        _toast('Product created.');
      } else {
        await widget.api.updateProduct(input);
        _toast('Product updated.');
      }
      await refresh();
    } catch (e) {
      _toast(e.toString(), error: true);
    }
  }

  Future<void> _delete(AdminProduct product) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('"${product.productName}" will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.api.deleteProduct(product.productId);
      _toast('Product deleted.');
      await refresh();
    } catch (e) {
      _toast(e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    final scheme = Theme.of(context).colorScheme;
    final filterOptions = _activeCategories;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Add product'),
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by name or brand...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(_search.clear),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int?>(
              key: ValueKey('filter-${filterOptions.length}-$_categoryFilter'),
              initialValue: _categoryFilter,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('All categories'),
                ),
                for (final c in filterOptions)
                  DropdownMenuItem<int?>(
                    value: c.id,
                    child: Text(c.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() => _categoryFilter = v),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${items.length} products',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const Spacer(),
                FilterChip(
                  label: const Text('Show deleted'),
                  selected: _showDeleted,
                  onSelected: (v) => setState(() => _showDeleted = v),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 48, color: scheme.error),
                    const SizedBox(height: 8),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 56, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text('No products found',
                        style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              )
            else
              ...items.map(
                (p) => Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ProductImage(
                      urls: [p.imageUrl],
                      baseUrl: widget.baseUrl,
                      size: 56,
                    ),
                    title: Text(
                      p.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        decoration:
                            p.isDeleted ? TextDecoration.lineThrough : null,
                        color: p.isDeleted ? Colors.grey : null,
                      ),
                    ),
                    subtitle: Text(
                      '${p.brand} • ${p.categoryName}'
                      '${p.isDeleted ? ' • Deleted' : ''}',
                    ),
                    trailing: p.isDeleted
                        ? null
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Edit',
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _openEditor(p),
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                onPressed: () => _delete(p),
                              ),
                            ],
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
