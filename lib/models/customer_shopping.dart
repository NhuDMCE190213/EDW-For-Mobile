import '../core/format.dart';

//Tiêu Gia Huy
class ShopProduct {
  const ShopProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.imageUrl,
    required this.variants,
  });
  final int id;
  final String name, brand, category;
  final String? imageUrl;
  final List<ShopVariant> variants;

  factory ShopProduct.fromJson(Map<String, dynamic> json) => ShopProduct(
    id: (json['productId'] ?? json['ProductId']) as int,
    name: (json['productName'] ?? json['ProductName']) as String,
    brand: json['brand'] as String? ?? '',
    category: json['categoryName'] as String? ?? '',
    imageUrl: json['imageUrl'] as String?,
    variants: ((json['variants'] ?? json['productVariants'] ?? []) as List)
        .map((v) => ShopVariant.fromJson(v as Map<String, dynamic>))
        .toList(),
  );
  double? get fromPrice => variants.isEmpty
      ? null
      : variants.map((v) => v.price).reduce((a, b) => a < b ? a : b);
}

class ShopVariant {
  const ShopVariant({
    required this.id,
    required this.sku,
    required this.color,
    required this.configuration,
    required this.price,
    required this.stock,
  });
  final String id, sku, color, configuration;
  final double price;
  final int stock;
  factory ShopVariant.fromJson(Map<String, dynamic> json) => ShopVariant(
    id: (json['productVariantId'] ?? json['ProductVariantId']) as String,
    sku: json['sku'] as String? ?? '',
    color: json['color'] as String? ?? '',
    configuration: [
      json['cpu'],
      json['ram'],
      json['storage'],
      json['screenSize'],
    ].whereType<String>().where((s) => s.isNotEmpty).join(' / '),
    price: (json['price'] as num).toDouble(),
    stock: json['stockQuantity'] as int,
  );
}

class ShopCartItem {
  const ShopCartItem({
    required this.id,
    required this.name,
    required this.sku,
    required this.quantity,
    required this.stock,
    required this.unitPrice,
    required this.totalPrice,
    this.imageUrl,
  });
  final int id, quantity, stock;
  final String name, sku;
  final String? imageUrl;
  final double unitPrice, totalPrice;
  factory ShopCartItem.fromJson(Map<String, dynamic> json) {
    final variant = _mapValue(json, 'productVariant');
    final product = _mapValue(variant, 'product');
    final quantity = _numberValue(json, 'quantity').toInt();
    final unitPrice = _numberValue(
      json,
      'unitPrice',
      fallback: _numberValue(variant, 'price'),
    ).toDouble();
    return ShopCartItem(
      id: _numberValue(json, 'cartItemId').toInt(),
      name:
          _stringValue(
            json,
            'productName',
            fallback: _stringValue(product, 'productName'),
          ) ??
          'Product',
      sku:
          _stringValue(json, 'sku', fallback: _stringValue(variant, 'sku')) ??
          '',
      quantity: quantity,
      stock: _numberValue(
        json,
        'stockQuantity',
        fallback: _numberValue(variant, 'stockQuantity'),
      ).toInt(),
      unitPrice: unitPrice,
      totalPrice: _numberValue(
        json,
        'totalPrice',
        fallback: unitPrice * quantity,
      ).toDouble(),
      imageUrl: _stringValue(
        json,
        'imageUrl',
        fallback: _stringValue(variant, 'imageUrl'),
      ),
    );
  }
}

Map<String, dynamic>? _mapValue(Map<String, dynamic>? json, String key) {
  final value = json?[key] ?? json?[key[0].toUpperCase() + key.substring(1)];
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return null;
}

String? _stringValue(
  Map<String, dynamic>? json,
  String key, {
  String? fallback,
}) {
  final value = json?[key] ?? json?[key[0].toUpperCase() + key.substring(1)];
  return value?.toString() ?? fallback;
}

num _numberValue(Map<String, dynamic>? json, String key, {num fallback = 0}) {
  final value = json?[key] ?? json?[key[0].toUpperCase() + key.substring(1)];
  return value is num
      ? value
      : num.tryParse(value?.toString() ?? '') ?? fallback;
}

String shoppingMoney(double amount) => formatVnd(amount);
