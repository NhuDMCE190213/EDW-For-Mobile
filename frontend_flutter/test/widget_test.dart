import 'package:flutter_test/flutter_test.dart';

import 'package:frontend_flutter/models/admin_catalog.dart';
import 'package:frontend_flutter/models/product_variant.dart';

void main() {
  test('variant JSON mapping preserves staff fields', () {
    final variant = ProductVariant.fromJson({
      'productVariantId': '00000000-0000-0000-0000-000000000001',
      'sku': 'PHONE-BLK-128',
      'color': 'Black',
      'storage': '128GB',
      'ram': '8GB',
      'price': 29000000,
      'stockQuantity': 12,
      'productId': 7,
      'promotion': {'name': 'Launch promotion'},
    });

    expect(variant.sku, 'PHONE-BLK-128');
    expect(variant.productId, 7);
    expect(variant.price, 29000000);
    expect(variant.promotionName, 'Launch promotion');
  });

  test('admin catalog JSON mapping preserves category and product fields', () {
    final category = AdminCategory.fromJson({
      'id': 3,
      'name': 'Laptops',
      'isDeleted': false,
      'createdAt': '2026-10-08T10:00:00Z',
    });
    final product = AdminProduct.fromJson({
      'productId': 12,
      'productName': 'XtremeBook 14',
      'brand': 'ElectroNexus',
      'categoryId': 3,
      'categoryName': 'Laptops',
      'imageUrl': 'https://example.com/laptop.png',
      'isDeleted': true,
    });

    expect(category.name, 'Laptops');
    expect(category.createdAt, isNotNull);
    expect(product.productId, 12);
    expect(product.categoryName, 'Laptops');
    expect(product.isDeleted, isTrue);
  });
}
