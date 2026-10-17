//Tiêu Gia Huy
import 'package:flutter/material.dart';

class ShoppingImage extends StatelessWidget {
  const ShoppingImage({super.key, required this.url, this.size = 88});
  final String? url;
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: url == null
        ? const Icon(Icons.devices_outlined, size: 36)
        : Image.network(
            url!,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) =>
                const Icon(Icons.broken_image_outlined, size: 36),
          ),
  );
}

class ShoppingMessage extends StatelessWidget {
  const ShoppingMessage({
    super.key,
    required this.message,
    required this.onRetry,
  });
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    ),
  );
}
