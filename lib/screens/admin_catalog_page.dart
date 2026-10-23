import 'package:flutter/material.dart';

import '../models/admin_catalog.dart';
import '../services/admin_catalog_api.dart';
import '../widgets/management_header.dart';

class AdminCatalogPage extends StatelessWidget {
  const AdminCatalogPage({super.key, required this.api});

  final AdminCatalogApi api;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Catalog Management'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.category_outlined), text: 'Categories'),
              Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Products'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            CategoryManagementPage(api: api),
            ProductManagementPage(api: api),
          ],
        ),
      ),
    );
  }
}

class CategoryManagementPage extends StatefulWidget {
  const CategoryManagementPage({super.key, required this.api});

  final AdminCatalogApi api;

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> {
  final _searchController = TextEditingController();
  List<AdminCategory> _categories = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool showSpinner = true}) async {
    if (showSpinner) setState(() => _loading = true);
    try {
      final categories = await widget.api.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  List<AdminCategory> get _filteredCategories {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _categories;
    return _categories
        .where((category) => category.name.toLowerCase().contains(query))
        .toList();
  }

  Future<void> _showEditor({AdminCategory? category}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => CategoryEditorDialog(api: widget.api, category: category),
    );
    if (saved == true) _load(showSpinner: false);
  }

  Future<void> _delete(AdminCategory category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text('This will mark "${category.name}" as deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.api.deleteCategory(category.id);
      _showMessage('Category deleted.');
      _load(showSpinner: false);
    } catch (error) {
      _showMessage(error.toString(), isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ManagementHeader(
            title: 'Category library',
            subtitle: 'Organize the departments customers browse.',
            icon: Icons.category_rounded,
            compact: true,
          ),
          _CatalogToolbar(
            searchController: _searchController,
            searchLabel: 'Search categories',
            addLabel: 'Add category',
            onAdd: () => _showEditor(),
            onRefresh: _loading ? null : _load,
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _load);
    }
    final categories = _filteredCategories;
    if (categories.isEmpty) {
      return const _EmptyState(message: 'No categories found.');
    }

    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth < 720
          ? ListView.separated(
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, index) => _CategoryCard(
                category: categories[index],
                onEdit: () => _showEditor(category: categories[index]),
                onDelete: categories[index].isDeleted
                    ? null
                    : () => _delete(categories[index]),
              ),
            )
          : SingleChildScrollView(
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: DataTable(
                  horizontalMargin: 16,
                  columnSpacing: 28,
                  columns: const [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('NAME')),
                    DataColumn(label: Text('STATUS')),
                    DataColumn(label: Text('CREATED')),
                    DataColumn(label: Text('UPDATED')),
                    DataColumn(label: Text('ACTIONS')),
                  ],
                  rows: categories
                      .map(
                        (category) => DataRow(
                          cells: [
                            DataCell(Text('${category.id}')),
                            DataCell(Text(category.name)),
                            DataCell(
                              _StatusChip(isDeleted: category.isDeleted),
                            ),
                            DataCell(Text(_formatDate(category.createdAt))),
                            DataCell(Text(_formatDate(category.updatedAt))),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () =>
                                        _showEditor(category: category),
                                    icon: const Icon(Icons.edit_outlined),
                                    tooltip: 'Edit',
                                  ),
                                  IconButton(
                                    onPressed: category.isDeleted
                                        ? null
                                        : () => _delete(category),
                                    icon: const Icon(Icons.delete_outline),
                                    color: Colors.red,
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
    );
  }
}

class ProductManagementPage extends StatefulWidget {
  const ProductManagementPage({super.key, required this.api});

  final AdminCatalogApi api;

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage> {
  final _searchController = TextEditingController();
  List<AdminProduct> _products = [];
  List<AdminCategory> _categories = [];
  int? _selectedCategoryId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool showSpinner = true}) async {
    if (showSpinner) setState(() => _loading = true);
    try {
      final productsFuture = widget.api.getProducts();
      final categoriesFuture = widget.api.getCategories();
      final products = await productsFuture;
      final categories = await categoriesFuture;
      if (!mounted) return;
      setState(() {
        _products = products;
        _categories = categories;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  List<AdminProduct> get _filteredProducts {
    final query = _searchController.text.trim().toLowerCase();
    return _products.where((product) {
      final matchesQuery =
          query.isEmpty ||
          product.productName.toLowerCase().contains(query) ||
          product.brand.toLowerCase().contains(query) ||
          product.categoryName.toLowerCase().contains(query);
      final matchesCategory =
          _selectedCategoryId == null ||
          product.categoryId == _selectedCategoryId;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  Future<void> _showEditor({AdminProduct? product}) async {
    final activeCategories = _categories
        .where((category) => !category.isDeleted)
        .toList();
    if (activeCategories.isEmpty && product == null) {
      _showMessage('Create an active category before adding products.');
      return;
    }
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => ProductEditorDialog(
        api: widget.api,
        categories: _categories,
        product: product,
      ),
    );
    if (saved == true) _load(showSpinner: false);
  }

  Future<void> _delete(AdminProduct product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('This will mark "${product.productName}" as deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.api.deleteProduct(product.productId);
      _showMessage('Product deleted.');
      _load(showSpinner: false);
    } catch (error) {
      _showMessage(error.toString(), isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ManagementHeader(
            title: 'Product catalog',
            subtitle: 'Keep product details and categories up to date.',
            icon: Icons.devices_other_rounded,
            compact: true,
          ),
          _CatalogToolbar(
            searchController: _searchController,
            searchLabel: 'Search products',
            addLabel: 'Add product',
            onAdd: () => _showEditor(),
            onRefresh: _loading ? null : _load,
            trailing: _CategoryFilter(
              categories: _categories,
              value: _selectedCategoryId,
              onChanged: (value) => setState(() => _selectedCategoryId = value),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _load);
    }
    final products = _filteredProducts;
    if (products.isEmpty) {
      return const _EmptyState(message: 'No products found.');
    }

    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth < 820
          ? ListView.separated(
              itemCount: products.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, index) => _ProductCard(
                product: products[index],
                onEdit: () => _showEditor(product: products[index]),
                onDelete: products[index].isDeleted
                    ? null
                    : () => _delete(products[index]),
              ),
            )
          : SingleChildScrollView(
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: DataTable(
                  dataRowMinHeight: 68,
                  dataRowMaxHeight: 92,
                  horizontalMargin: 16,
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(label: Text('PRODUCT')),
                    DataColumn(label: Text('BRAND')),
                    DataColumn(label: Text('CATEGORY')),
                    DataColumn(label: Text('STATUS')),
                    DataColumn(label: Text('UPDATED')),
                    DataColumn(label: Text('ACTIONS')),
                  ],
                  rows: products
                      .map(
                        (product) => DataRow(
                          cells: [
                            DataCell(
                              SizedBox(
                                width: 280,
                                child: Row(
                                  children: [
                                    _ProductImage(
                                      url: product.imageUrl,
                                      size: 44,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '#${product.productId} ${product.productName}',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DataCell(Text(product.brand)),
                            DataCell(Text(product.categoryName)),
                            DataCell(_StatusChip(isDeleted: product.isDeleted)),
                            DataCell(Text(_formatDate(product.updatedAt))),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () =>
                                        _showEditor(product: product),
                                    icon: const Icon(Icons.edit_outlined),
                                    tooltip: 'Edit',
                                  ),
                                  IconButton(
                                    onPressed: product.isDeleted
                                        ? null
                                        : () => _delete(product),
                                    icon: const Icon(Icons.delete_outline),
                                    color: Colors.red,
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
    );
  }
}

class CategoryEditorDialog extends StatefulWidget {
  const CategoryEditorDialog({super.key, required this.api, this.category});

  final AdminCatalogApi api;
  final AdminCategory? category;

  @override
  State<CategoryEditorDialog> createState() => _CategoryEditorDialogState();
}

class _CategoryEditorDialogState extends State<CategoryEditorDialog> {
  late final TextEditingController _nameController;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Category name is required.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final input = CategoryInput(id: widget.category?.id, name: name);
    try {
      if (widget.category == null) {
        await widget.api.createCategory(input);
      } else {
        await widget.api.updateCategory(input);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.category != null;
    return AlertDialog(
      title: Text(editing ? 'Update category' : 'Create category'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Category name *',
                prefixIcon: Icon(Icons.category_outlined),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) {
                if (!_saving) _save();
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

class ProductEditorDialog extends StatefulWidget {
  const ProductEditorDialog({
    super.key,
    required this.api,
    required this.categories,
    this.product,
  });

  final AdminCatalogApi api;
  final List<AdminCategory> categories;
  final AdminProduct? product;

  @override
  State<ProductEditorDialog> createState() => _ProductEditorDialogState();
}

class _ProductEditorDialogState extends State<ProductEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _imageUrlController;
  int? _categoryId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.productName);
    _brandController = TextEditingController(text: product?.brand);
    _imageUrlController = TextEditingController(text: product?.imageUrl);
    final categories = _availableCategories;
    _categoryId =
        product?.categoryId ??
        (categories.isEmpty ? null : categories.first.id);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  List<AdminCategory> get _availableCategories {
    final currentCategoryId = widget.product?.categoryId;
    return widget.categories
        .where(
          (category) => !category.isDeleted || category.id == currentCategoryId,
        )
        .toList();
  }

  Future<void> _save() async {
    final productName = _nameController.text.trim();
    final brand = _brandController.text.trim();
    final imageUrl = _imageUrlController.text.trim();
    if (productName.isEmpty || brand.isEmpty || _categoryId == null) {
      setState(() => _error = 'Name, brand, and category are required.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final input = ProductInput(
      productId: widget.product?.productId,
      productName: productName,
      brand: brand,
      categoryId: _categoryId!,
      imageUrl: imageUrl.isEmpty ? null : imageUrl,
    );
    try {
      if (widget.product == null) {
        await widget.api.createProduct(input);
      } else {
        await widget.api.updateProduct(input);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.product != null;
    final categories = _availableCategories;
    return AlertDialog(
      title: Text(editing ? 'Update product' : 'Create product'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              TextField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Product name *',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _brandController,
                decoration: const InputDecoration(
                  labelText: 'Brand *',
                  prefixIcon: Icon(Icons.business_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _categoryId,
                items: categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category.id,
                        child: Text(
                          category.isDeleted
                              ? '${category.name} (deleted)'
                              : category.name,
                        ),
                      ),
                    )
                    .toList(),
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  prefixIcon: Icon(Icons.category_outlined),
                  border: OutlineInputBorder(),
                ),
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _categoryId = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  prefixIcon: Icon(Icons.image_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

class _CatalogToolbar extends StatelessWidget {
  const _CatalogToolbar({
    required this.searchController,
    required this.searchLabel,
    required this.addLabel,
    required this.onAdd,
    required this.onRefresh,
    this.trailing,
  });

  final TextEditingController searchController;
  final String searchLabel;
  final String addLabel;
  final VoidCallback onAdd;
  final VoidCallback? onRefresh;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final search = TextField(
      controller: searchController,
      decoration: InputDecoration(
        labelText: searchLabel,
        prefixIcon: const Icon(Icons.search),
        border: const OutlineInputBorder(),
      ),
    );
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: Text(addLabel),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              if (trailing != null) ...[const SizedBox(height: 8), trailing!],
              const SizedBox(height: 8),
              actions,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: search),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              SizedBox(width: 240, child: trailing!),
            ],
            const SizedBox(width: 12),
            actions,
          ],
        );
      },
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({
    required this.categories,
    required this.value,
    required this.onChanged,
  });

  final List<AdminCategory> categories;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int?>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Category',
        prefixIcon: Icon(Icons.filter_list),
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text('All categories'),
        ),
        ...categories.map(
          (category) => DropdownMenuItem<int?>(
            value: category.id,
            child: Text(
              category.isDeleted ? '${category.name} (deleted)' : category.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final AdminCategory category;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(child: Text('${category.id}')),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text('Created: ${_formatDate(category.createdAt)}'),
                ],
              ),
            ),
            _StatusChip(isDeleted: category.isDeleted),
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              color: Colors.red,
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  final AdminProduct product;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProductImage(url: product.imageUrl, size: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text('${product.brand} - ${product.categoryName}'),
                  const SizedBox(height: 6),
                  _StatusChip(isDeleted: product.isDeleted),
                ],
              ),
            ),
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              color: Colors.red,
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.url, required this.size});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url?.trim();
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image_outlined),
    );

    if (imageUrl == null || imageUrl.isEmpty) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isDeleted});

  final bool isDeleted;

  @override
  Widget build(BuildContext context) {
    final color = isDeleted ? Colors.red : Colors.green;
    return Chip(
      label: Text(isDeleted ? 'Deleted' : 'Active'),
      backgroundColor: color.withValues(alpha: .12),
      labelStyle: TextStyle(color: color.shade700),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 48),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message));
  }
}

String _formatDate(DateTime? value) {
  if (value == null) return '-';
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}
