class AdminCategory {
  const AdminCategory({
    required this.id,
    required this.name,
    required this.isDeleted,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AdminCategory.fromJson(Map<String, dynamic> json) {
    return AdminCategory(
      id: _int(json['id'] ?? json['Id']),
      name: _string(json['name'] ?? json['Name']),
      isDeleted: _bool(json['isDeleted'] ?? json['IsDeleted']),
      createdAt: _date(json['createdAt'] ?? json['CreatedAt']),
      updatedAt: _date(json['updatedAt'] ?? json['UpdatedAt']),
    );
  }
}

class AdminProduct {
  const AdminProduct({
    required this.productId,
    required this.productName,
    required this.brand,
    required this.categoryId,
    required this.categoryName,
    required this.isDeleted,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
  });

  final int productId;
  final String productName;
  final String brand;
  final int categoryId;
  final String categoryName;
  final String? imageUrl;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AdminProduct.fromJson(Map<String, dynamic> json) {
    return AdminProduct(
      productId: _int(json['productId'] ?? json['ProductId']),
      productName: _string(json['productName'] ?? json['ProductName']),
      brand: _string(json['brand'] ?? json['Brand']),
      categoryId: _int(json['categoryId'] ?? json['CategoryId']),
      categoryName: _string(json['categoryName'] ?? json['CategoryName']),
      imageUrl: _nullableString(json['imageUrl'] ?? json['ImageUrl']),
      isDeleted: _bool(json['isDeleted'] ?? json['IsDeleted']),
      createdAt: _date(json['createdAt'] ?? json['CreatedAt']),
      updatedAt: _date(json['updatedAt'] ?? json['UpdatedAt']),
    );
  }
}

class CategoryInput {
  const CategoryInput({required this.name, this.id});

  final int? id;
  final String name;

  Map<String, dynamic> toJson({bool includeId = false}) {
    return {if (includeId) 'id': id, 'name': name};
  }
}

class ProductInput {
  const ProductInput({
    required this.productName,
    required this.brand,
    required this.categoryId,
    this.productId,
    this.imageUrl,
  });

  final int? productId;
  final String productName;
  final String brand;
  final int categoryId;
  final String? imageUrl;

  Map<String, dynamic> toJson({bool includeId = false}) {
    return {
      if (includeId) 'productId': productId,
      'productName': productName,
      'brand': brand,
      'categoryId': categoryId,
      'imageUrl': imageUrl,
    };
  }
}

DateTime? _date(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

int _int(Object? value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

bool _bool(Object? value) {
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  return false;
}

String _string(Object? value) => value?.toString() ?? '';

String? _nullableString(Object? value) {
  final string = value?.toString().trim();
  return string == null || string.isEmpty ? null : string;
}
