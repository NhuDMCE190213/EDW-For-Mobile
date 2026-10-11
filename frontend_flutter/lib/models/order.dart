import 'package:frontend_flutter/models/product_variant.dart';

class Order {
  final String orderId;
  final int customerId;
  final String customerName;
  final int? promotionId;
  final double totalAmount;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<OrderItem> orderItems;

  Order({
    required this.orderId,
    required this.customerId,
    required this.customerName,
    this.promotionId,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    required this.orderItems,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['orderId'] as String,
      customerId: json['customerId'] as int,
      customerName: json['customerName'] as String,
      promotionId: json['promotionId'] as int?,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      orderItems: (json['orderItems'] as List)
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class OrderItem {
  final int orderItemId;
  final String orderId;
  final String productVariantId;
  final String productName;
  final String productVariantDetails;
  final int quantity;
  final double priceAtPurchase;
  final DateTime createdAt;
  final DateTime? updatedAt;

  OrderItem({
    required this.orderItemId,
    required this.orderId,
    required this.productVariantId,
    required this.productName,
    required this.productVariantDetails,
    required this.quantity,
    required this.priceAtPurchase,
    required this.createdAt,
    this.updatedAt,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      orderItemId: json['orderItemId'] as int,
      orderId: json['orderId'] as String,
      productVariantId: json['productVariantId'] as String,
      productName: json['productName'] as String,
      productVariantDetails: json['productVariantDetails'] as String,
      quantity: json['quantity'] as int,
      priceAtPurchase: (json['priceAtPurchase'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }
}
