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
  factory ShopCartItem.fromJson(Map<String, dynamic> json) => ShopCartItem(
    id: json['cartItemId'] as int,
    name:
        json['productName'] as String? ??
        ((json['productVariant'] as Map?)?['product'] as Map?)?['productName']
            as String? ??
        'Product',
    sku:
        json['sku'] as String? ??
        (json['productVariant'] as Map?)?['sku'] as String? ??
        '',
    quantity: json['quantity'] as int,
    stock:
        (json['stockQuantity'] as num?)?.toInt() ??
        ((json['productVariant'] as Map?)?['stockQuantity'] as num?)?.toInt() ??
        0,
    unitPrice:
        (json['unitPrice'] as num?)?.toDouble() ??
        ((json['productVariant'] as Map?)?['price'] as num?)?.toDouble() ??
        0,
    totalPrice:
        (json['totalPrice'] as num?)?.toDouble() ??
        (((json['unitPrice'] as num?)?.toDouble() ??
                ((json['productVariant'] as Map?)?['price'] as num?)
                    ?.toDouble() ??
                0) *
            (json['quantity'] as num).toInt()),
    imageUrl:
        json['imageUrl'] as String? ??
        (json['productVariant'] as Map?)?['imageUrl'] as String?,
  );
}

String shoppingMoney(double amount) =>
    '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')} VND';
