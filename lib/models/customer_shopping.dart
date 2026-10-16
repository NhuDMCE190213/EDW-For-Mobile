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
    id: json['productId'] as int,
    name: json['productName'] as String,
    brand: json['brand'] as String? ?? '',
    category: json['categoryName'] as String? ?? '',
    imageUrl: json['imageUrl'] as String?,
    variants: (json['variants'] as List)
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
    id: json['productVariantId'] as String,
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
  factory ShopCartItem.fromJson(Map<String, dynamic> json) => ShopCartItem(
    id: json['cartItemId'] as int,
    name: json['productName'] as String,
    sku: json['sku'] as String? ?? '',
    quantity: json['quantity'] as int,
    stock: json['stockQuantity'] as int,
    unitPrice: (json['unitPrice'] as num).toDouble(),
    totalPrice: (json['totalPrice'] as num).toDouble(),
    imageUrl: json['imageUrl'] as String?,
  );
}

String shoppingMoney(double amount) =>
    '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')} VND';
