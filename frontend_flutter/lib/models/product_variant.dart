class ProductSummary {
  const ProductSummary({required this.id, required this.name});

  final int id;
  final String name;

  factory ProductSummary.fromJson(Map<String, dynamic> json) {
    return ProductSummary(
      id: json['productId'] as int,
      name: json['productName'] as String? ?? 'Product ${json['productId']}',
    );
  }
}

class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.sku,
    required this.color,
    required this.cpu,
    required this.ram,
    required this.storage,
    required this.screenSize,
    required this.price,
    required this.stockQuantity,
    required this.imageUrl,
    required this.productId,
    required this.promotionName,
    required this.promotionId,
  });

  final String id;
  final String sku;
  final String color;
  final String? cpu;
  final String? ram;
  final String? storage;
  final String? screenSize;
  final double price;
  final int stockQuantity;
  final String? imageUrl;
  final int productId;
  final String? promotionName;
  final String? promotionId;

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    final promotion = _asMap(json['promotion'] ?? json['Promotion']);
    final promotionName =
        promotion?['name'] ?? promotion?['Name'] ?? json['promotionName'];
    return ProductVariant(
      id: json['productVariantId'] as String,
      sku: json['sku'] as String? ?? '',
      color: json['color'] as String? ?? '',
      cpu: json['cpu'] as String?,
      ram: json['ram'] as String?,
      storage: json['storage'] as String?,
      screenSize: json['screenSize'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      stockQuantity: (json['stockQuantity'] as num?)?.toInt() ?? 0,
      imageUrl: json['imageUrl'] as String?,
      productId: (json['productId'] as num).toInt(),
      promotionName: promotionName as String?,
      promotionId:
          json['promotionId'] as String? ?? json['PromotionId'] as String?,
    );
  }

  static Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }
}

class ProductVariantInput {
  const ProductVariantInput({
    required this.color,
    required this.cpu,
    required this.ram,
    required this.storage,
    required this.screenSize,
    required this.price,
    required this.stockQuantity,
    required this.imageUrl,
    required this.productId,
    this.productVariantId,
    this.promotionId,
  });

  final String color;
  final String? cpu;
  final String? ram;
  final String? storage;
  final String? screenSize;
  final double price;
  final int stockQuantity;
  final String? imageUrl;
  final int productId;
  final String? productVariantId;
  final String? promotionId;

  Map<String, dynamic> toJson({bool includeId = false}) {
    final json = <String, dynamic>{
      'color': color,
      'cpu': cpu,
      'ram': ram,
      'storage': storage,
      'screenSize': screenSize,
      'price': price,
      'stockQuantity': stockQuantity,
      'imageUrl': imageUrl,
      'productId': productId,
      'promotionId': promotionId,
    };
    if (includeId) {
      json['productVariantId'] = productVariantId;
    }
    return json;
  }
}
