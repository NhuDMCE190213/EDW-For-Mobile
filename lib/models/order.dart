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
      orderId: (json['orderId'] ?? json['OrderId']) as String,
      customerId: (json['customerId'] ?? json['CustomerId']) as int,
      customerName: (json['customerName'] ?? json['CustomerName'] ?? '') as String,
      promotionId: (json['promotionId'] ?? json['PromotionId']) as int?,
      totalAmount: ((json['totalAmount'] ?? json['TotalAmount'] ?? 0) as num).toDouble(),
      status: (json['status'] ?? json['Status'] ?? 'Pending') as String,
      createdAt: DateTime.parse((json['createdAt'] ?? json['CreatedAt']) as String),
      updatedAt: json['updatedAt'] != null || json['UpdatedAt'] != null
          ? DateTime.parse((json['updatedAt'] ?? json['UpdatedAt']) as String)
          : null,
      orderItems: ((json['orderItems'] ?? json['OrderItems'] ?? []) as List)
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
      orderItemId: (json['orderItemId'] ?? json['OrderItemId'] ?? 0) as int,
      orderId: (json['orderId'] ?? json['OrderId'] ?? '') as String,
      productVariantId: (json['productVariantId'] ?? json['ProductVariantId'] ?? '') as String,
      productName: (json['productName'] ?? json['ProductName'] ?? 'Product') as String,
      productVariantDetails: (json['productVariantDetails'] ?? json['ProductVariantDetails'] ?? '') as String,
      quantity: (json['quantity'] ?? json['Quantity'] ?? 1) as int,
      priceAtPurchase: ((json['priceAtPurchase'] ?? json['PriceAtPurchase'] ?? 0) as num).toDouble(),
      createdAt: json['createdAt'] != null || json['CreatedAt'] != null
          ? DateTime.parse((json['createdAt'] ?? json['CreatedAt']) as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null || json['UpdatedAt'] != null
          ? DateTime.parse((json['updatedAt'] ?? json['UpdatedAt']) as String)
          : null,
    );
  }
}

class OrderDashboard {
  final int totalOrders;
  final double totalRevenue;
  final int pendingOrders;
  final int completedOrders;
  final int cancelledOrders;

  OrderDashboard({
    required this.totalOrders,
    required this.totalRevenue,
    required this.pendingOrders,
    required this.completedOrders,
    required this.cancelledOrders,
  });

  factory OrderDashboard.fromJson(Map<String, dynamic> json) {
    return OrderDashboard(
      totalOrders: (json['totalOrders'] ?? json['TotalOrders'] ?? 0) as int,
      totalRevenue: ((json['totalRevenue'] ?? json['TotalRevenue'] ?? 0) as num).toDouble(),
      pendingOrders: (json['pendingOrders'] ?? json['PendingOrders'] ?? 0) as int,
      completedOrders: (json['completedOrders'] ?? json['CompletedOrders'] ?? 0) as int,
      cancelledOrders: (json['cancelledOrders'] ?? json['CancelledOrders'] ?? 0) as int,
    );
  }
}

class CheckoutResult {
  final Order order;
  final double subtotal;
  final double discount;
  final double shipping;
  final double total;
  final String paymentStatus;

  CheckoutResult({
    required this.order,
    required this.subtotal,
    required this.discount,
    required this.shipping,
    required this.total,
    required this.paymentStatus,
  });

  factory CheckoutResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] != null ? json['data'] as Map<String, dynamic> : json;
    final orderJson = (data['order'] ?? data['Order']) as Map<String, dynamic>;
    return CheckoutResult(
      order: Order.fromJson(orderJson),
      subtotal: ((data['subtotal'] ?? data['Subtotal'] ?? 0) as num).toDouble(),
      discount: ((data['discount'] ?? data['Discount'] ?? 0) as num).toDouble(),
      shipping: ((data['shipping'] ?? data['Shipping'] ?? 0) as num).toDouble(),
      total: ((data['total'] ?? data['Total'] ?? 0) as num).toDouble(),
      paymentStatus: (data['paymentStatus'] ?? data['PaymentStatus'] ?? 'Unpaid') as String,
    );
  }
}
