import 'package:flutter/material.dart';

import '../models/order.dart';
import '../services/cart_api.dart';
import 'customer_cart_page.dart';
import '../models/product_variant.dart';
import '../services/order_api.dart';
import '../services/review_api.dart';
import '../services/staff_variant_api.dart';
import 'write_review_page.dart';

class CustomerOrdersPage extends StatefulWidget {
  const CustomerOrdersPage({
    super.key,
    required this.api,
    this.cartApi,
    required this.customerId,
  });

  final OrderApi api;
  final CartApi? cartApi;
  final int customerId;

  @override
  State<CustomerOrdersPage> createState() => _CustomerOrdersPageState();
}

class _CustomerOrdersPageState extends State<CustomerOrdersPage> {
  List<Order> _orders = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  final Set<String> _transferringOrderIds = {};
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading orders: $e')),
        );
      }
    }
  }

  Future<void> _transferToCart(String orderId) async {
    setState(() => _transferringOrderIds.add(orderId));
    try {
      await widget.api.transferToCart(orderId, widget.customerId);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Items transferred to cart successfully!'),
          backgroundColor: Colors.green,
          action: widget.cartApi != null
              ? SnackBarAction(
                  label: 'Go to Cart',
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CustomerCartPage(
                          api: widget.cartApi!,
                          orderApi: widget.api,
                          customerId: widget.customerId,
                        ),
                      ),
                    );
                  },
                )
              : null,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error transferring to cart: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _transferringOrderIds.remove(orderId));
      }
    }
  }

  Future<void> _cancelOrder(String orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await widget.api.cancelOrder(orderId);
      await _fetchOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order cancelled successfully'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Colors.green;
      case 'pending': return Colors.orange;
      case 'processing':
      case 'confirmed':
      case 'shipped': return Colors.blue;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  Future<void> _openReviewForItem(Order order, OrderItem item) async {
    int productId = 1;
    final matchedVariant = _variants.cast<ProductVariant?>().firstWhere(
      (v) => v?.id.toLowerCase() == item.productVariantId.toLowerCase(),
      orElse: () => null,
    );

    if (matchedVariant != null && matchedVariant.productId > 0) {
      productId = matchedVariant.productId;
    } else {
      try {
        final variantApi = StaffVariantApi(baseUrl: widget.api.baseUrl);
        final freshVariants = await variantApi.getVariants();
        _variants = freshVariants;
        final found = freshVariants.cast<ProductVariant?>().firstWhere(
          (v) => v?.id.toLowerCase() == item.productVariantId.toLowerCase(),
          orElse: () => null,
        );
        if (found != null && found.productId > 0) {
          productId = found.productId;
        } else {
          final products = await variantApi.getProducts();
          final prod = products.cast<ProductSummary?>().firstWhere(
            (p) => p?.name.toLowerCase() == item.productName.toLowerCase(),
            orElse: () => null,
          );
          if (prod != null) productId = prod.id;
        }
      } catch (_) {}
    }

    if (!mounted) return;
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => WriteReviewPage(
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
    final filteredOrders = _selectedFilter == 'All'
        ? _orders
        : _orders
            .where((o) =>
                o.status.toLowerCase() == _selectedFilter.toLowerCase())
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        actions: [
          IconButton(
            onPressed: () async {
              await _fetchOrders();
              await _loadVariants();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ['All', 'Pending', 'Completed', 'Cancelled'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _selectedFilter = filter),
                    selectedColor: const Color(0xFFE24B4A).withValues(alpha: 0.15),
                    checkmarkColor: const Color(0xFFE24B4A),
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFFE24B4A) : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredOrders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 70, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          _selectedFilter == 'All' ? 'You have no orders yet' : 'No $_selectedFilter orders found',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      await _fetchOrders();
                      await _loadVariants();
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];
                        final statusColor = _getStatusColor(order.status);
                        final isTransferring = _transferringOrderIds.contains(order.orderId);
                        final isCompleted = order.status.toLowerCase() == 'completed';

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          elevation: 1.5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Order #${order.orderId.length > 8 ? order.orderId.substring(0, 8) : order.orderId}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        order.status,
                                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Date: ${order.createdAt.toLocal().toString().substring(0, 16)}',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                                const Divider(height: 20),
                                const Text('Items:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(height: 4),
                                ...order.orderItems.map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                              Text(
                                                'Qty: ${item.quantity} | Total: \$${(item.priceAtPurchase * item.quantity).toStringAsFixed(2)}',
                                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isCompleted)
                                          TextButton.icon(
                                            onPressed: () => _openReviewForItem(order, item),
                                            icon: const Icon(Icons.rate_review_outlined, size: 16, color: Colors.amber),
                                            label: const Text(
                                              'Đánh giá',
                                              style: TextStyle(fontSize: 13, color: Colors.amber, fontWeight: FontWeight.bold),
                                            ),
                                            style: TextButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              visualDensity: VisualDensity.compact,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    Text(
                                      '\$${order.totalAmount.toStringAsFixed(2)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFFE24B4A)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (order.status.toLowerCase() == 'pending') ...[
                                      OutlinedButton.icon(
                                        onPressed: () => _cancelOrder(order.orderId),
                                        icon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.red),
                                        label: const Text('Cancel', style: TextStyle(color: Colors.red)),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    FilledButton.icon(
                                      onPressed: isTransferring ? null : () => _transferToCart(order.orderId),
                                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE24B4A)),
                                      icon: isTransferring
                                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                          : const Icon(Icons.shopping_cart_checkout, size: 16),
                                      label: Text(
                                        isCompleted || order.status.toLowerCase() == 'cancelled' ? 'Re-order to Cart' : 'Transfer to Cart',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}