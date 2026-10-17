import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import '../services/cart_api.dart';
import '../services/order_api.dart';
import 'customer_orders_page.dart';

class CustomerCartPage extends StatefulWidget {
  const CustomerCartPage({
    super.key,
    required this.api,
    this.orderApi,
    required this.customerId,
  });

  final CartApi api;
  final OrderApi? orderApi;
  final int customerId;

  @override
  State<CustomerCartPage> createState() => _CustomerCartPageState();
}

class _CustomerCartPageState extends State<CustomerCartPage> {
  List<CartItem> _cartItems = [];
  final Set<int> _selectedItemIds = {};
  bool _isLoading = true;
  bool _isCheckingOut = false;
  final Set<int> _updatingItemIds = {};

  @override
  void initState() {
    super.initState();
    _fetchCart();
  }

  Future<void> _fetchCart() async {
    setState(() => _isLoading = true);
    try {
      final items = await widget.api.getCartItems(widget.customerId);
      setState(() {
        _cartItems = items;
        // By default select all items
        _selectedItemIds.clear();
        for (var item in items) {
          _selectedItemIds.add(item.cartItemId);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading cart: $e')),
        );
      }
    }
  }

  Future<void> _updateQuantity(CartItem item, int delta) async {
    final newQty = item.quantity + delta;
    if (newQty <= 0) {
      _confirmRemoveItem(item.cartItemId);
      return;
    }

    if (newQty > item.productVariant.stockQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot add more. Only ${item.productVariant.stockQuantity} items in stock.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _updatingItemIds.add(item.cartItemId));
    try {
      await widget.api.updateQuantity(
        item.cartItemId,
        newQty,
        widget.customerId,
      );
      await _fetchCart();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating quantity: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _updatingItemIds.remove(item.cartItemId));
      }
    }
  }

  void _confirmRemoveItem(int cartItemId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove item'),
        content: const Text('Are you sure you want to remove this item from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _removeItem(cartItemId);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeItem(int cartItemId) async {
    try {
      await widget.api.removeFromCart(cartItemId, widget.customerId);
      _selectedItemIds.remove(cartItemId);
      await _fetchCart();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item removed from cart')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing item: $e')),
        );
      }
    }
  }

  double _calculateSelectedTotal() {
    double total = 0;
    for (var item in _cartItems) {
      if (_selectedItemIds.contains(item.cartItemId)) {
        total += item.productVariant.price * item.quantity;
      }
    }
    return total;
  }

  Future<void> _handleCheckout() async {
    if (widget.orderApi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order service is unavailable')),
      );
      return;
    }

    if (_selectedItemIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one item to checkout'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final total = _calculateSelectedTotal();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.shopping_bag_outlined, color: Color(0xFFE24B4A)),
            SizedBox(width: 8),
            Text('Confirm Checkout'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Selected Items: ${_selectedItemIds.length}'),
            const SizedBox(height: 8),
            Text(
              'Total Amount: \$${total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFFE24B4A),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Would you like to place this order now?',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE24B4A),
            ),
            child: const Text('Place Order'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isCheckingOut = true);
    try {
      final result = await widget.orderApi!.checkoutCart(
        widget.customerId,
        _selectedItemIds.toList(),
      );

      if (!mounted) return;
      setState(() => _isCheckingOut = false);

      // Show Checkout Success Dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          icon: const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 56,
          ),
          title: const Text('Checkout Successful!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order ID: #${result.order.orderId.length > 8 ? result.order.orderId.substring(0, 8) : result.order.orderId}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text('Subtotal: \$${result.subtotal.toStringAsFixed(2)}'),
              if (result.discount > 0)
                Text(
                  'Discount: -\$${result.discount.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.green),
                ),
              Text('Shipping: \$${result.shipping.toStringAsFixed(2)}'),
              const Divider(),
              Text(
                'Total Paid: \$${result.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFFE24B4A),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  'Status: ${result.order.status}',
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _fetchCart();
              },
              child: const Text('Continue Shopping'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomerOrdersPage(
                      api: widget.orderApi!,
                      customerId: widget.customerId,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.receipt_long),
              label: const Text('View Orders'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE24B4A),
              ),
            ),
          ],
        ),
      );

      _fetchCart();
    } catch (e) {
      setState(() => _isCheckingOut = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checkout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allSelected = _cartItems.isNotEmpty &&
        _selectedItemIds.length == _cartItems.length;
    final selectedTotal = _calculateSelectedTotal();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        actions: [
          if (_cartItems.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  if (allSelected) {
                    _selectedItemIds.clear();
                  } else {
                    _selectedItemIds.clear();
                    for (var i in _cartItems) {
                      _selectedItemIds.add(i.cartItemId);
                    }
                  }
                });
              },
              icon: Icon(
                allSelected ? Icons.check_box : Icons.check_box_outline_blank,
                size: 20,
              ),
              label: Text(allSelected ? 'Deselect All' : 'Select All'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.remove_shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your cart is empty',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Browse items and add them to your cart!',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchCart,
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 100),
                itemCount: _cartItems.length,
                itemBuilder: (context, index) {
                  final item = _cartItems[index];
                  final isSelected = _selectedItemIds.contains(item.cartItemId);
                  final isUpdating = _updatingItemIds.contains(item.cartItemId);

                  final variant = item.productVariant;
                  final specText = [
                    if (variant.ram != null && variant.ram!.isNotEmpty)
                      '${variant.ram} RAM',
                    if (variant.storage != null && variant.storage!.isNotEmpty)
                      variant.storage,
                    if (variant.color.isNotEmpty) variant.color,
                  ].join(' • ');

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                            : Colors.grey.shade200,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: isSelected,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedItemIds.add(item.cartItemId);
                                } else {
                                  _selectedItemIds.remove(item.cartItemId);
                                }
                              });
                            },
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: variant.imageUrl != null &&
                                    variant.imageUrl!.isNotEmpty
                                ? Image.network(
                                    variant.imageUrl!,
                                    width: 68,
                                    height: 68,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      width: 68,
                                      height: 68,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.devices, size: 30),
                                    ),
                                  )
                                : Container(
                                    width: 68,
                                    height: 68,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.devices, size: 30),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  variant.sku.isNotEmpty
                                      ? variant.sku
                                      : 'Variant ${variant.id.substring(0, 8)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                if (specText.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    specText,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Text(
                                  '\$${variant.price.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Quantity selector
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            onTap: isUpdating
                                                ? null
                                                : () =>
                                                    _updateQuantity(item, -1),
                                            borderRadius:
                                                const BorderRadius.horizontal(
                                              left: Radius.circular(8),
                                            ),
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              child: Icon(Icons.remove, size: 18),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                            child: isUpdating
                                                ? const SizedBox(
                                                    width: 14,
                                                    height: 14,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : Text(
                                                    '${item.quantity}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                          ),
                                          InkWell(
                                            onTap: isUpdating
                                                ? null
                                                : () =>
                                                    _updateQuantity(item, 1),
                                            borderRadius:
                                                const BorderRadius.horizontal(
                                              right: Radius.circular(8),
                                            ),
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              child: Icon(Icons.add, size: 18),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Remove button
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      onPressed: () =>
                                          _confirmRemoveItem(item.cartItemId),
                                      tooltip: 'Remove',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      bottomSheet: _cartItems.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected (${_selectedItemIds.length})',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '\$${selectedTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE24B4A),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _isCheckingOut || _selectedItemIds.isEmpty
                          ? null
                          : _handleCheckout,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE24B4A),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isCheckingOut
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.shopping_cart_checkout),
                      label: Text(
                        _isCheckingOut ? 'Processing...' : 'Checkout',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

