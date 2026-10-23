//Tiêu Gia Huy
import 'package:flutter/material.dart';

class ShoppingImage extends StatelessWidget {
  const ShoppingImage({super.key, required this.url, this.size = 88});
  final String? url;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
    ),
    clipBehavior: Clip.antiAlias,
    child: url == null
        ? Icon(
            Icons.devices_outlined,
            size: 36,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          )
        : Image.network(
            url!,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Icon(
              Icons.broken_image_outlined,
              size: 36,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
  );
}

class ShoppingMessage extends StatelessWidget {
  const ShoppingMessage({
    super.key,
    required this.message,
    required this.onRetry,
    this.icon = Icons.info_outline,
    this.retryLabel = 'Refresh',
  });
  final String message;
  final VoidCallback onRetry;
  final IconData icon;
  final String retryLabel;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
        Icon(icon, size: 44, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
          label: Text(retryLabel),
          ),
        ],
      ),
    ),
  );
}
