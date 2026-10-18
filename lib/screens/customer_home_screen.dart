import 'package:flutter/material.dart';

//Tiêu Gia Huy
import 'customer_shopping/customer_shopping_page.dart';

import '../models/auth_model.dart';
import '../services/auth_api.dart';
import '../services/cart_api.dart';
import '../services/customer_shopping_api.dart';
import '../services/order_api.dart';
import 'customer_cart_page.dart';
import 'customer_orders_page.dart';
import 'customer_reviews_page.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import '../services/review_api.dart';
import 'customer_shopping/product_catalog_view.dart';

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
  late final CustomerShoppingApi _shoppingApi;

  @override
  void initState() {
    super.initState();
    _shoppingApi = CustomerShoppingApi(
      baseUrl: widget.baseUrl,
      token: widget.user.token,
    );
  }

  @override
  void dispose() {
    _shoppingApi.close();
    super.dispose();
  }

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
          customerId: widget.user.userId,
          orderApi: widget.orderApi,
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
          orderApi: widget.orderApi,
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
          if (!_loggingOut)
            CustomerShoppingEntry(
              baseUrl: widget.baseUrl,
              token: widget.user.token,
              customerId: widget.user.userId,
              orderApi: widget.orderApi,
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
            onPressed: _openReviews,
            icon: const Icon(Icons.rate_review_outlined),
            tooltip: 'Đánh giá của tôi',
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
          : ProductCatalogView(
              api: _shoppingApi,
              customerId: widget.user.userId,
            ),
    );
  }
}
