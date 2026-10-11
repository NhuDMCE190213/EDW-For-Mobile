import 'package:flutter/material.dart';

import '../models/product_variant.dart';
import '../services/auth_api.dart';
import '../services/staff_variant_api.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class StaffVariantPage extends StatefulWidget {
  const StaffVariantPage({
    super.key,
    required this.api,
    this.authToken,
    this.authApi,
    this.baseUrl,
  });

  final StaffVariantApi api;
  final String? authToken;
  final AuthApi? authApi;
  final String? baseUrl;

  @override
  State<StaffVariantPage> createState() => _StaffVariantPageState();
}

class _StaffVariantPageState extends State<StaffVariantPage> {
  List<ProductSummary> _products = [];
  List<ProductVariant> _variants = [];
  int? _selectedProductId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool showSpinner = true}) async {
    if (showSpinner) setState(() => _loading = true);
    try {
      final products = await widget.api.getProducts();
      final variants = await widget.api.getVariants(
        productId: _selectedProductId,
      );
      if (!mounted) return;
      setState(() {
        _products = products;
        _variants = variants;
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

  Future<void> _showEditor({ProductVariant? variant}) async {
    if (variant == null && _selectedProductId == null) {
      _showMessage('Select a product before adding a variant.');
      return;
    }
    final productId = variant?.productId ?? _selectedProductId!;
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => VariantEditorDialog(
        api: widget.api,
        productId: productId,
        variant: variant,
      ),
    );
    if (saved == true) _load(showSpinner: false);
  }

  Future<void> _delete(ProductVariant variant) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete variant?'),
        content: Text(
          'This will delete ${variant.sku.isEmpty ? variant.color : variant.sku}.',
        ),
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
      await widget.api.delete(variant.id);
      _showMessage('Variant deleted.');
      _load(showSpinner: false);
    } catch (error) {
      _showMessage(error.toString(), isError: true);
    }
  }

  Future<void> _stockIn(ProductVariant variant) async {
    final amountController = TextEditingController();
    final amount = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Restock ${variant.sku}'),
        content: TextField(
          controller: amountController,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Quantity to add',
            suffixText: 'units',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(amountController.text);
              if (value == null || value <= 0) return;
              Navigator.pop(context, value);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    amountController.dispose();
    if (amount == null) return;
    try {
      await widget.api.stockIn(variant.id, amount);
      _showMessage('Stock updated.');
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

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất tài khoản nhân viên?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE24B4A)),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    if (widget.authApi != null && widget.authToken != null) {
      try {
        await widget.authApi!.logout(widget.authToken!);
      } catch (_) {}
    }

    if (!mounted) return;
    if (widget.authApi != null && widget.baseUrl != null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(
            authApi: widget.authApi!,
            baseUrl: widget.baseUrl!,
          ),
        ),
        (route) => false,
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Variant Management'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          if (widget.authToken != null && widget.baseUrl != null)
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(
                      token: widget.authToken!,
                      role: 'Staff',
                      baseUrl: widget.baseUrl!,
                      authApi: widget.authApi,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.account_circle_outlined),
              tooltip: 'Hồ sơ cá nhân',
            ),
          if (widget.authApi != null)
            IconButton(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout),
              tooltip: 'Đăng xuất',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final productPicker = DropdownButtonFormField<int?>(
                  initialValue: _selectedProductId,
                  decoration: const InputDecoration(
                    labelText: 'Product',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('All products'),
                    ),
                    ..._products.map(
                      (product) => DropdownMenuItem<int?>(
                        value: product.id,
                        child: Text(
                          '${product.id} - ${product.name}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedProductId = value);
                    _load();
                  },
                );
                final addButton = FilledButton.icon(
                  onPressed: () => _showEditor(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add variant'),
                );
                if (constraints.maxWidth < 520) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      productPicker,
                      const SizedBox(height: 8),
                      addButton,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: productPicker),
                    const SizedBox(width: 12),
                    addButton,
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('Try again')),
          ],
        ),
      );
    }
    if (_variants.isEmpty) {
      return const Center(child: Text('No variant data yet.'));
    }
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth < 700
          ? ListView.separated(
              itemCount: _variants.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, index) => _VariantCard(
                variant: _variants[index],
                onEdit: () => _showEditor(variant: _variants[index]),
                onDelete: () => _delete(_variants[index]),
                onStockIn: () => _stockIn(_variants[index]),
              ),
            )
          : SingleChildScrollView(
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: DataTable(
                  dataRowMinHeight: 72,
                  dataRowMaxHeight: 150,
                  headingRowHeight: 56,
                  horizontalMargin: 16,
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(label: Text('SKU / COLOR')),
                    DataColumn(label: Text('CONFIGURATION')),
                    DataColumn(label: Text('PRICE')),
                    DataColumn(label: Text('STOCK')),
                    DataColumn(label: Text('PROMOTION')),
                    DataColumn(label: Text('ACTIONS')),
                  ],
                  rows: _variants
                      .map(
                        (variant) => DataRow(
                          cells: [
                            DataCell(Text('${variant.sku}\n${variant.color}')),
                            DataCell(
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minWidth: 220,
                                  maxWidth: 280,
                                ),
                                child: _ConfigurationTags(variant: variant),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${_money(variant.price)}\nVND',
                                maxLines: 2,
                              ),
                            ),
                            DataCell(
                              _StockBadge(quantity: variant.stockQuantity),
                            ),
                            DataCell(
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 180,
                                ),
                                child: Text(
                                  variant.promotionName ??
                                      (variant.promotionId == null
                                          ? '-'
                                          : 'Promotion assigned'),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () => _stockIn(variant),
                                    icon: const Icon(
                                      Icons.inventory_2_outlined,
                                    ),
                                    tooltip: 'Restock',
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        _showEditor(variant: variant),
                                    icon: const Icon(Icons.edit_outlined),
                                    tooltip: 'Edit',
                                  ),
                                  IconButton(
                                    onPressed: () => _delete(variant),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
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

  String _money(double value) => value
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match.group(1)},',
      );
}

class _VariantCard extends StatelessWidget {
  const _VariantCard({
    required this.variant,
    required this.onEdit,
    required this.onDelete,
    required this.onStockIn,
  });

  final ProductVariant variant;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onStockIn;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  child: Text(
                    variant.color.isEmpty
                        ? '?'
                        : variant.color[0].toUpperCase(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${variant.sku} • ${variant.color}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 8),
                _StockBadge(quantity: variant.stockQuantity),
              ],
            ),
            const SizedBox(height: 8),
            _ConfigurationTags(variant: variant),
            const SizedBox(height: 4),
            Text('${_formatMoney(variant.price)} VND'),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: onStockIn,
                  icon: const Icon(Icons.inventory_2_outlined),
                  tooltip: 'Restock',
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit',
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatMoney(double value) => value
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match.group(1)},',
      );
}

class _ConfigurationTags extends StatelessWidget {
  const _ConfigurationTags({required this.variant});

  final ProductVariant variant;

  @override
  Widget build(BuildContext context) {
    final tags = <String>[
      if (variant.ram?.isNotEmpty == true) 'RAM: ${variant.ram}',
      if (variant.cpu?.isNotEmpty == true) 'CPU: ${variant.cpu}',
      if (variant.screenSize?.isNotEmpty == true)
        'Screen: ${variant.screenSize}',
      if (variant.storage?.isNotEmpty == true) 'Storage: ${variant.storage}',
    ];

    if (tags.isEmpty) {
      return Text(
        'No configuration',
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: Colors.grey.shade600),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: tags
          .map(
            (tag) => Container(
              constraints: const BoxConstraints(maxWidth: 220),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                tag,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: Colors.grey.shade800),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.quantity});

  final int quantity;

  @override
  Widget build(BuildContext context) {
    final (label, color) = quantity == 0
        ? ('Out of stock', Colors.red)
        : quantity <= 10
        ? ('$quantity', Colors.orange)
        : ('$quantity', Colors.green);
    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: .15),
      labelStyle: TextStyle(color: color),
    );
  }
}

class VariantEditorDialog extends StatefulWidget {
  const VariantEditorDialog({
    super.key,
    required this.api,
    required this.productId,
    this.variant,
  });

  final StaffVariantApi api;
  final int productId;
  final ProductVariant? variant;

  @override
  State<VariantEditorDialog> createState() => _VariantEditorDialogState();
}

class _VariantEditorDialogState extends State<VariantEditorDialog> {
  late final Map<String, TextEditingController> _controllers;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final variant = widget.variant;
    _controllers = {
      'color': TextEditingController(text: variant?.color),
      'storage': TextEditingController(text: variant?.storage),
      'ram': TextEditingController(text: variant?.ram),
      'screenSize': TextEditingController(text: variant?.screenSize),
      'cpu': TextEditingController(text: variant?.cpu),
      'price': TextEditingController(
        text: variant == null ? '' : variant.price.toStringAsFixed(0),
      ),
      'stockQuantity': TextEditingController(
        text: variant == null ? '' : '${variant.stockQuantity}',
      ),
      'imageUrl': TextEditingController(text: variant?.imageUrl),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final color = _controllers['color']!.text.trim();
    final price = double.tryParse(_controllers['price']!.text.trim());
    final stock = int.tryParse(_controllers['stockQuantity']!.text.trim());
    if (color.isEmpty ||
        price == null ||
        price < 0 ||
        stock == null ||
        stock < 0) {
      setState(
        () => _error =
            'Color, a non-negative price, and stock quantity are required.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final input = ProductVariantInput(
      productVariantId: widget.variant?.id,
      color: color,
      cpu: _optional('cpu'),
      ram: _optional('ram'),
      storage: _optional('storage'),
      screenSize: _optional('screenSize'),
      price: price,
      stockQuantity: stock,
      imageUrl: _optional('imageUrl'),
      productId: widget.productId,
    );
    try {
      if (widget.variant == null) {
        await widget.api.create(input);
      } else {
        await widget.api.update(input);
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error.toString();
        });
      }
    }
  }

  String? _optional(String key) {
    final value = _controllers[key]!.text.trim();
    return value.isEmpty ? null : value;
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.variant != null;
    return AlertDialog(
      title: Text(editing ? 'Update product variant' : 'Add product variant'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null)
                Text(_error!, style: TextStyle(color: Colors.red.shade700)),
              _field('color', 'Color *', hint: 'Matte black, Titanium...'),
              Row(
                children: [
                  Expanded(child: _field('storage', 'Storage', hint: '128GB')),
                  const SizedBox(width: 8),
                  Expanded(child: _field('ram', 'RAM', hint: '8GB')),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      'screenSize',
                      'Screen size',
                      hint: '6.1 inch',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _field('cpu', 'CPU', hint: 'Snapdragon 8 Gen 3'),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _field('price', 'Price (VND) *', numeric: true),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _field(
                      'stockQuantity',
                      'Stock quantity *',
                      numeric: true,
                    ),
                  ),
                ],
              ),
              _field('imageUrl', 'Image URL', hint: 'https://...'),
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

  Widget _field(
    String key,
    String label, {
    String? hint,
    bool numeric = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _controllers[key],
        keyboardType: numeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
