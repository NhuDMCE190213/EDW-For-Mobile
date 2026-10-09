import 'product_variant.dart';

class CartItem {
  final int cartItemId;
  final int customerId;
  final String productVariantId;
  final int quantity;
  final ProductVariant productVariant;

  CartItem({
    required this.cartItemId,
    required this.customerId,
    required this.productVariantId,
    required this.quantity,
    required this.productVariant,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      cartItemId: json['cartItemId'] as int,
      customerId: json['customerId'] as int,
      productVariantId: json['productVariantId'] as String,
      quantity: json['quantity'] as int,
      productVariant:
          ProductVariant.fromJson(json['productVariant'] as Map<String, dynamic>),
    );
  }
}
