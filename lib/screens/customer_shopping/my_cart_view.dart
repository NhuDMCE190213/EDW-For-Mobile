//Tiêu Gia Huy
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/customer_shopping.dart';
import '../../services/customer_shopping_api.dart';
import '../../services/order_api.dart';
import 'shopping_widgets.dart';

class MyCartView extends StatefulWidget {
  const MyCartView({
    super.key,
    required this.api,
    this.orderApi,
    this.customerId = 0,
  });
  final CustomerShoppingApi api;
  final OrderApi? orderApi;
  final int customerId;
  @override
  State<MyCartView> createState() => _MyCartViewState();
}

class _MyCartViewState extends State<MyCartView> {
  List<ShopCartItem> _items = [];
  bool _loading = true, _busy = false;
  bool _checkingOut = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.api.getCart();
      if (mounted) setState(() => _items = items);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _mutate(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit(ShopCartItem item) async {
    final quantity = await showDialog<int>(
      context: context,
      builder: (_) => CartQuantityDialog(item: item),
    );
    if (!mounted || quantity == null || quantity == item.quantity) return;
    await _mutate(() => widget.api.updateQuantity(item.id, quantity));
  }

  Future<void> _remove(ShopCartItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove product?'),
        content: Text('Remove ${item.name} (${item.sku}) from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (mounted && confirmed == true) {
      await _mutate(() => widget.api.removeItem(item.id));
    }
  }

  Future<void> _checkout() async {
      if (_checkingOut || _items.isEmpty || widget.orderApi == null) return;
      final total = _items.fold<double>(
        0,
        (sum, item) => sum + item.totalPrice,
      );
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm checkout'),
          content: Text(
            '${_items.length} item(s)\nTotal: ${shoppingMoney(total)}\n\n'
            'Place this order now?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Place order'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      setState(() => _checkingOut = true);
      try {
        final result = await widget.orderApi!.checkoutCart(
          widget.customerId,
          _items.map((item) => item.id).toList(),
        );
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 52),
            title: const Text('Checkout successful'),
            content: Text(
              'Order created successfully.\n'
              'Total: ${shoppingMoney(result.total)}',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
        );
        if (mounted) await _load();
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(error.toString())));
        }
      } finally {
        if (mounted) setState(() => _checkingOut = false);
      }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return ShoppingMessage(message: _error!, onRetry: _load);
    }
    if (_items.isEmpty) {
      return ShoppingMessage(message: 'Your cart is empty.', onRetry: _load);
    }
    final total = _items.fold<double>(0, (sum, item) => sum + item.totalPrice);
    return Column(
      children: [
        if (_busy || _checkingOut) const LinearProgressIndicator(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              if (!_busy) await _load();
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, _) => const Divider(height: 32),
              itemBuilder: (context, index) {
                final item = _items[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShoppingImage(url: widget.api.imageUrl(item.imageUrl)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(item.sku),
                              Text(shoppingMoney(item.unitPrice)),
                              Text(
                                item.stock > 0
                                    ? 'In stock: ${item.stock}'
                                    : 'Out of stock',
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _busy ? null : () => _remove(item),
                          tooltip: 'Remove product',
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        IconButton(
                          onPressed: _busy || item.quantity <= 1
                              ? null
                              : () => _mutate(
                                  () => widget.api.updateQuantity(
                                    item.id,
                                    item.quantity - 1,
                                  ),
                                ),
                          tooltip: 'Decrease quantity',
                          icon: const Icon(Icons.remove),
                        ),
                        Text(
                          '${item.quantity}',
                          key: ValueKey('quantity-${item.id}'),
                        ),
                        IconButton(
                          onPressed: _busy || item.quantity >= item.stock
                              ? null
                              : () => _mutate(
                                  () => widget.api.updateQuantity(
                                    item.id,
                                    item.quantity + 1,
                                  ),
                                ),
                          tooltip: 'Increase quantity',
                          icon: const Icon(Icons.add),
                        ),
                        IconButton(
                          onPressed: _busy || item.stock < 1
                              ? null
                              : () => _edit(item),
                          tooltip: 'Enter quantity',
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        Text('Subtotal: ${shoppingMoney(item.totalPrice)}'),
                      ],
                    ),
                    if (item.quantity > item.stock)
                      const Text('Quantity exceeds current stock.'),
                  ],
                );
              },
            ),
          ),
        ),
        const Divider(height: 1),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Total: ${shoppingMoney(total)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (widget.orderApi != null)
                  FilledButton.icon(
                    onPressed: _busy || _checkingOut ? null : _checkout,
                    icon: const Icon(Icons.shopping_cart_checkout),
                    label: const Text('Checkout'),
                  ),
                IconButton(
                  onPressed: _busy ? null : _load,
                  tooltip: 'Refresh cart',
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class CartQuantityDialog extends StatefulWidget {
  const CartQuantityDialog({super.key, required this.item});
  final ShopCartItem item;
  @override
  State<CartQuantityDialog> createState() => _CartQuantityDialogState();
}

class _CartQuantityDialogState extends State<CartQuantityDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _quantity;
  @override
  void initState() {
    super.initState();
    _quantity = TextEditingController(text: '${widget.item.quantity}');
  }

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  void _save() {
    if (_form.currentState!.validate()) {
      Navigator.pop(context, int.parse(_quantity.text));
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Update quantity'),
    content: Form(
      key: _form,
      child: TextFormField(
        controller: _quantity,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: 'Quantity',
          helperText: 'Available: ${widget.item.stock}',
        ),
        validator: (value) {
          final quantity = int.tryParse(value ?? '');
          if (quantity == null || quantity < 1) {
            return 'Enter a whole number of at least 1.';
          }
          if (quantity > widget.item.stock) {
            return 'Only ${widget.item.stock} available.';
          }
          return null;
        },
        onFieldSubmitted: (_) => _save(),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _save, child: const Text('Save')),
    ],
  );
}
