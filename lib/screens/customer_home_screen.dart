import 'package:flutter/material.dart';

//Tiêu Gia Huy
import 'customer_shopping/customer_shopping_page.dart';

import '../models/auth_model.dart';
import '../services/auth_api.dart';
import '../services/cart_api.dart';
import '../services/order_api.dart';
import 'customer_cart_page.dart';
import 'customer_orders_page.dart';
import 'customer_reviews_page.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import '../services/review_api.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({
    super.key,
    required this.user,
    required this.authApi,
    required this.baseUrl,
    required this.cartApi,
    required this.orderApi,
  });

  final LoginResponse user;
  final AuthApi authApi;
  final String baseUrl;
  final CartApi cartApi;
  final OrderApi orderApi;

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  bool _loggingOut = false;

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ÄÄƒng xuáº¥t'),
        content: const Text(
          'Báº¡n cÃ³ cháº¯c cháº¯n muá»‘n Ä‘Äƒng xuáº¥t khá»i tÃ i khoáº£n khÃ´ng?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Há»§y'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE24B4A),
            ),
            child: const Text('ÄÄƒng xuáº¥t'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _loggingOut = true);
    try {
      // UC-02: Gá»i API logout
      await widget.authApi.logout(widget.user.token);
    } catch (_) {
      // JWT lÃ  stateless, dÃ¹ API cÃ³ lá»—i máº¡ng thÃ¬ váº«n xÃ³a phiÃªn á»Ÿ client
    }

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('ÄÃ£ Ä‘Äƒng xuáº¥t thÃ nh cÃ´ng.')));

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LoginScreen(authApi: widget.authApi, baseUrl: widget.baseUrl),
      ),
      (route) => false,
    );
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          token: widget.user.token,
          role: widget.user.role,
          baseUrl: widget.baseUrl,
          authApi: widget.authApi,
        ),
      ),
    );
  }

  //Tiêu Gia Huy
  void _openShoppingCart() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CustomerShoppingPage(
          baseUrl: widget.baseUrl,
          token: widget.user.token,
          initialTab: 1,
        ),
      ),
    );
  }

  //Tiêu Gia Huy
  // Keep the legacy cart handler intact.
  // ignore: unused_element
  void _openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerCartPage(
          api: widget.cartApi,
          customerId: widget.user.userId,
        ),
      ),
    );
  }

  void _openOrders() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerOrdersPage(
          api: widget.orderApi,
          customerId: widget.user.userId,
        ),
      ),
    );
  }

  void _openReviews() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerReviewsPage(
          api: ReviewApi(baseUrl: widget.baseUrl),
          customerId: widget.user.userId,
          customerName: widget.user.fullName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EDW Customer'),
        actions: [
          //Tiêu Gia Huy
          if (!_loggingOut) CustomerShoppingEntry(
            baseUrl: widget.baseUrl,
            token: widget.user.token,
          ),
          IconButton(
            //Tiêu Gia Huy
            onPressed: _openShoppingCart,
            icon: const Icon(Icons.shopping_cart_outlined),
            tooltip: 'Giá» hÃ ng',
          ),
          IconButton(
            onPressed: _openOrders,
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'ÄÆ¡n hÃ ng cá»§a tÃ´i',
          ),
          IconButton(
            onPressed: _openReviews,
            icon: const Icon(Icons.rate_review_outlined),
            tooltip: 'Đánh giá của tôi',
          ),
          IconButton(
            onPressed: _openProfile,
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Há»“ sÆ¡ cÃ¡ nhÃ¢n',
          ),
          IconButton(
            onPressed: _loggingOut ? null : _handleLogout,
            icon: const Icon(Icons.logout),
            tooltip: 'ÄÄƒng xuáº¥t',
          ),
        ],
      ),
      body: _loggingOut
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InkWell(
                    onTap: _openProfile,
                    borderRadius: BorderRadius.circular(16),
                    child: Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.primaryContainer
                          .withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary
                              .withValues(alpha: 0.2),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: const Color(0xFFE24B4A),
                              child: Text(
                                widget.user.fullName.isNotEmpty
                                    ? widget.user.fullName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.user.fullName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.user.email,
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 8),
                            Chip(
                              label: Text(
                                'Vai trÃ²: ${widget.user.roleDisplayName}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              backgroundColor: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _openProfile,
                    icon: const Icon(Icons.badge_outlined),
                    label: const Text('Xem & Quáº£n lÃ½ Há»“ sÆ¡'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    //Tiêu Gia Huy
                    onPressed: _openShoppingCart,
                    icon: const Icon(Icons.shopping_cart_outlined),
                    label: const Text('Xem giá» hÃ ng'),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _openOrders,
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('My Orders'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _openReviews,
                    icon: const Icon(Icons.rate_review_outlined),
                    label: const Text('Đánh giá của tôi'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  //Tiêu Gia Huy
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CustomerShoppingPage(
                          baseUrl: widget.baseUrl,
                          token: widget.user.token,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.storefront_outlined),
                    label: const Text('View Product'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ChÃ o má»«ng báº¡n Ä‘áº¿n vá»›i EDW Store!',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Báº¡n Ä‘Ã£ Ä‘Äƒng nháº­p thÃ nh cÃ´ng vá»›i vai trÃ² KhÃ¡ch hÃ ng.',
                    style: TextStyle(color: Colors.grey.shade600, height: 1.4),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _loggingOut ? null : _handleLogout,
                    icon: const Icon(Icons.logout),
                    label: const Text('ÄÄƒng xuáº¥t khá»i tÃ i khoáº£n'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE24B4A),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

