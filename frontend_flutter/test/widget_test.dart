import 'package:flutter_test/flutter_test.dart';

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
}
