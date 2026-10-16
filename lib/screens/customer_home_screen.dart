import 'package:flutter/material.dart';

//Tiêu Gia Huy
import 'customer_shopping/customer_shopping_page.dart';

import '../models/auth_model.dart';
import '../services/auth_api.dart';
import '../services/cart_api.dart';
import '../services/order_api.dart';
import 'customer_cart_page.dart';
import 'customer_orders_page.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

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
        title: const Text('Đăng xuất'),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE24B4A),
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _loggingOut = true);
    try {
      // UC-02: Gọi API logout
      await widget.authApi.logout(widget.user.token);
    } catch (_) {
      // JWT là stateless, dù API có lỗi mạng thì vẫn xóa phiên ở client
    }

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã đăng xuất thành công.')));

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
            tooltip: 'Giỏ hàng',
          ),
          IconButton(
            onPressed: _openOrders,
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Đơn hàng của tôi',
          ),
          IconButton(
            onPressed: _openProfile,
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Hồ sơ cá nhân',
          ),
          IconButton(
            onPressed: _loggingOut ? null : _handleLogout,
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
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
                                'Vai trò: ${widget.user.roleDisplayName}',
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
                    label: const Text('Xem & Quản lý Hồ sơ'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    //Tiêu Gia Huy
                    onPressed: _openShoppingCart,
                    icon: const Icon(Icons.shopping_cart_outlined),
                    label: const Text('Xem giỏ hàng'),
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
                    'Chào mừng bạn đến với EDW Store!',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bạn đã đăng nhập thành công với vai trò Khách hàng.',
                    style: TextStyle(color: Colors.grey.shade600, height: 1.4),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _loggingOut ? null : _handleLogout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Đăng xuất khỏi tài khoản'),
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
