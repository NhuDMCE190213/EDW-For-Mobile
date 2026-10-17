import 'package:flutter/material.dart';

import '../models/order.dart';
import '../models/product_variant.dart';
import '../services/order_api.dart';
import '../services/review_api.dart';
import '../services/staff_variant_api.dart';
import 'write_review_page.dart';

class CustomerOrdersPage extends StatefulWidget {
  const CustomerOrdersPage({
    super.key,
    required this.api,
    required this.customerId,
  });
  final OrderApi api;
  final int customerId;

  @override
  State<CustomerOrdersPage> createState() => _CustomerOrdersPageState();
}

class _CustomerOrdersPageState extends State<CustomerOrdersPage> {
  List<Order> _orders = [];
  bool _isLoading = true;
  List<ProductVariant> _variants = [];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    _loadVariants();
  }

  Future<void> _loadVariants() async {
    try {
      final variantApi = StaffVariantApi(baseUrl: widget.api.baseUrl);
      final variants = await variantApi.getVariants();
      if (mounted) {
        setState(() => _variants = variants);
      }
    } catch (_) {
      // Best-effort cache for product ID mapping
    }
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await widget.api.getMyOrders(widget.customerId);
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error loading orders: $e')));
      }
    }
  }

  Future<void> _transferToCart(String orderId) async {
    try {
      await widget.api.transferToCart(orderId, widget.customerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order transferred to cart')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error transferring to cart: $e')),
        );
      }
    }
  }

  Future<void> _openReviewForItem(Order order, OrderItem item) async {
    int productId = 1;

    // Tìm productId từ variant cache
    final matchedVariant = _variants.cast<ProductVariant?>().firstWhere(
      (v) =>
          v?.id.toLowerCase() == item.productVariantId.toLowerCase(),
      orElse: () => null,
    );

    if (matchedVariant != null && matchedVariant.productId > 0) {
      productId = matchedVariant.productId;
    } else {
      // Nếu chưa có, query nhanh lại variants
      try {
        final variantApi = StaffVariantApi(baseUrl: widget.api.baseUrl);
        final freshVariants = await variantApi.getVariants();
        _variants = freshVariants;
        final found = freshVariants.cast<ProductVariant?>().firstWhere(
          (v) =>
              v?.id.toLowerCase() == item.productVariantId.toLowerCase(),
          orElse: () => null,
        );
        if (found != null && found.productId > 0) {
          productId = found.productId;
        } else {
          // Thử tìm theo danh sách sản phẩm
          final products = await variantApi.getProducts();
          final prod = products.cast<ProductSummary?>().firstWhere(
            (p) =>
                p?.name.toLowerCase() == item.productName.toLowerCase(),
            orElse: () => null,
          );
          if (prod != null) {
            productId = prod.id;
          }
        }
      } catch (_) {}
    }

    if (!mounted) return;

    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder:
            (_) => WriteReviewPage(
              api: ReviewApi(baseUrl: widget.api.baseUrl),
              customerId: widget.customerId,
              productId: productId,
              productName: item.productName,
              orderId: order.orderId,
              orderItemId: item.orderItemId,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _fetchOrders();
                await _loadVariants();
              },
              child: ListView.builder(
                itemCount: _orders.length,
                itemBuilder: (context, index) {
                  final order = _orders[index];
                  final isCompleted = order.status == 'Completed';

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Order #${order.orderId.substring(0, 8)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Chip(
                                label: Text(order.status),
                                backgroundColor: isCompleted
                                    ? Colors.green.shade100
                                    : (order.status == 'Cancelled'
                                        ? Colors.red.shade100
                                        : Colors.blue.shade100),
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isCompleted
                                      ? Colors.green.shade900
                                      : (order.status == 'Cancelled'
                                          ? Colors.red.shade900
                                          : Colors.blue.shade900),
                                ),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Total: \$${order.totalAmount}'),
                          const SizedBox(height: 8),
                          const Text(
                            'Items:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          ...order.orderItems.map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.productName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          'Qty: ${item.quantity} | \$${item.priceAtPurchase}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isCompleted)
                                    TextButton.icon(
                                      onPressed:
                                          () => _openReviewForItem(order, item),
                                      icon: const Icon(
                                        Icons.rate_review_outlined,
                                        size: 16,
                                        color: Colors.amber,
                                      ),
                                      label: const Text(
                                        'Đánh giá',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.amber,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (order.status == 'Cancelled' ||
                              order.status == 'Completed')
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: () => _transferToCart(order.orderId),
                                icon: const Icon(Icons.shopping_cart),
                                label: const Text('Transfer to Cart'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
