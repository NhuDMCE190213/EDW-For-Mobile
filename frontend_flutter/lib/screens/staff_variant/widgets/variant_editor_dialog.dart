import 'package:flutter/material.dart';

import '../../../models/product_variant.dart';
import '../../../services/staff_variant_api.dart';

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
