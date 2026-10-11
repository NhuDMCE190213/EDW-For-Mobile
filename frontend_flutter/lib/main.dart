import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'screens/admin_catalog_page.dart';
import 'screens/customer_cart_page.dart';
import 'screens/customer_orders_page.dart';
import 'screens/staff_orders_page.dart';
import 'screens/staff_variant_page.dart';
import 'services/admin_catalog_api.dart';
import 'services/cart_api.dart';
import 'services/order_api.dart';
import 'services/staff_variant_api.dart';

void main() {
  final baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  final apiBaseUrl = baseUrl.isNotEmpty
      ? baseUrl
      : !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? 'http://10.0.2.2:5238'
      : 'http://localhost:5238';

  runApp(
    MyApp(
      adminApi: AdminCatalogApi(baseUrl: apiBaseUrl),
      variantApi: StaffVariantApi(baseUrl: apiBaseUrl),
      orderApi: OrderApi(baseUrl: apiBaseUrl),
      cartApi: CartApi(baseUrl: apiBaseUrl),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.adminApi,
    required this.variantApi,
    required this.orderApi,
    required this.cartApi,
  });

  final AdminCatalogApi adminApi;
  final StaffVariantApi variantApi;
  final OrderApi orderApi;
  final CartApi cartApi;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EDW Mobile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE24B4A)),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFF7F7F7),
        ),
      ),
      home: AppNavigation(
        adminApi: adminApi,
        variantApi: variantApi,
        orderApi: orderApi,
        cartApi: cartApi,
      ),
    );
  }
}

class AppNavigation extends StatefulWidget {
  const AppNavigation({
    super.key,
    required this.adminApi,
    required this.variantApi,
    required this.orderApi,
    required this.cartApi,
  });

  final AdminCatalogApi adminApi;
  final StaffVariantApi variantApi;
  final OrderApi orderApi;
  final CartApi cartApi;

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  int _currentIndex = 0;
  static const int mockCustomerId = 1;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      AdminCatalogPage(api: widget.adminApi),
      StaffVariantPage(api: widget.variantApi),
      StaffOrdersPage(api: widget.orderApi),
      CustomerOrdersPage(api: widget.orderApi, customerId: mockCustomerId),
      CustomerCartPage(api: widget.cartApi, customerId: mockCustomerId),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_customize_outlined),
            label: 'Catalog',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tune_outlined),
            label: 'Variants',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: 'All Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'My Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'Cart',
          ),
        ],
      ),
    );
  }
}
