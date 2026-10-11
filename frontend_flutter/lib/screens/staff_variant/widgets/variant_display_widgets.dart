import 'package:flutter/material.dart';

import '../../../models/product_variant.dart';

class ConfigurationTags extends StatelessWidget {
  const ConfigurationTags({super.key, required this.variant});

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

class StockBadge extends StatelessWidget {
  const StockBadge({super.key, required this.quantity});

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
