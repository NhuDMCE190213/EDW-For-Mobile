import 'package:flutter/material.dart';

import '../../../core/product_image.dart';

import '../../../models/product_variant.dart';
import 'variant_display_widgets.dart';

class VariantCard extends StatelessWidget {
  const VariantCard({
    super.key,
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
                ProductImage(
                  urls: [variant.imageUrl],
                  size: 56,
                  fallback: Text(
                    variant.color.isEmpty ? '?' : variant.color[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
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
                StockBadge(quantity: variant.stockQuantity),
              ],
            ),
            const SizedBox(height: 8),
            ConfigurationTags(variant: variant),
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
