import 'package:flutter/material.dart';

/// Shows a product/variant picture with a safe fallback chain:
///   1. first usable URL in [urls] (e.g. variant image)
///   2. next URL if the first fails to load (e.g. the product's image)
///   3. [fallback] widget, or a neutral placeholder icon
///
/// Relative paths (e.g. "/uploads/a.png") are resolved against [baseUrl].
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.urls,
    this.baseUrl,
    this.size = 64,
    this.radius = 10,
    this.fit = BoxFit.cover,
    this.fallback,
  });

  final List<String?> urls;
  final String? baseUrl;
  final double size;
  final double radius;
  final BoxFit fit;
  final Widget? fallback;

  List<String> get _candidates {
    final result = <String>[];
    // The backend may store several images in one string: "a.jpg;b.jpg".
    final parts = urls
        .expand((raw) => (raw ?? '').split(';'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);
    for (final value in parts) {
      var uri = Uri.tryParse(value);
      if (uri == null) continue;
      if (!uri.hasScheme && baseUrl != null) {
        uri = Uri.tryParse(baseUrl!)?.resolve(value);
      }
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        result.add(uri.toString());
      }
    }
    return result;
  }

  Widget _placeholder() => Container(
    width: size,
    height: size,
    color: Colors.grey.shade100,
    alignment: Alignment.center,
    child:
        fallback ??
        Icon(
          Icons.image_not_supported_outlined,
          size: size * 0.42,
          color: Colors.grey.shade400,
        ),
  );

  Widget _load(List<String> list, int index) {
    if (index >= list.length) return _placeholder();
    return Image.network(
      list[index],
      width: size,
      height: size,
      fit: fit,
      // On Flutter Web, most CDNs send no CORS headers, so the canvas decoder
      // fails. 'prefer' falls back to a plain <img> element, which works.
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : Container(
              width: size,
              height: size,
              color: Colors.grey.shade100,
              alignment: Alignment.center,
              child: const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
      errorBuilder: (_, error, _) {
        debugPrint('ProductImage failed: ${list[index]} -> $error');
        return _load(list, index + 1);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(width: size, height: size, child: _load(_candidates, 0)),
    );
  }
}
