import 'package:flutter/material.dart';

import '../models/product_variant.dart';
import '../services/staff_variant_api.dart';
import 'staff_variant/widgets/variant_card.dart';
import 'staff_variant/widgets/variant_display_widgets.dart';
import 'staff_variant/widgets/variant_editor_dialog.dart';

class StaffVariantPage extends StatefulWidget {
  const StaffVariantPage({
    super.key,
    required this.api,
    this.showAppBar = true,
  });

  final StaffVariantApi api;
  final bool showAppBar;

  @override
  State<StaffVariantPage> createState() => StaffVariantPageState();
}

class StaffVariantPageState extends State<StaffVariantPage> {
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

  Future<void> refresh() => _load();

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

  @override
  Widget build(BuildContext context) {
    final content = Padding(
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
    );

    if (!widget.showAppBar) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Variant Management'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: content,
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
              itemBuilder: (_, index) => VariantCard(
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
                                child: ConfigurationTags(variant: variant),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${_money(variant.price)}\nVND',
                                maxLines: 2,
                              ),
                            ),
                            DataCell(
                              StockBadge(quantity: variant.stockQuantity),
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
