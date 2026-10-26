import 'package:flutter/material.dart';

import '../core/app_theme.dart';

import '../core/format.dart';
import '../core/product_image.dart';

import '../models/cart_item.dart';
import '../services/cart_api.dart';

class CustomerCartPage extends StatefulWidget {
  const CustomerCartPage({
    super.key,
    required this.api,
    required this.customerId,
  });

  final CartApi api;
  final int customerId;

  @override
  State<CustomerCartPage> createState() => _CustomerCartPageState();
}

class _CustomerCartPageState extends State<CustomerCartPage> {
  List<CartItem> _cartItems = [];
  bool _isLoading = true;
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


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),

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
                  ].join(' ΓÇó ');

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

                          ProductImage(
                            urls: [variant.imageUrl],
                            size: 68,
                            radius: 8,
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
                                  '${formatVnd(variant.price)}',
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
    );
  }
}
