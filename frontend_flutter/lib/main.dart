import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'screens/customer_cart_page.dart';
import 'screens/customer_orders_page.dart';
import 'screens/promotion_page.dart';
import 'screens/staff_orders_page.dart';
import 'screens/staff_variant_page.dart';
import 'services/cart_api.dart';
import 'services/order_api.dart';
import 'services/promotion_api.dart';
import 'services/staff_variant_api.dart';

void main() {
  final baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  final apiBaseUrl = baseUrl.isNotEmpty
      ? baseUrl
      : kIsWeb
          ? 'http://localhost:5238'
          : 'http://10.0.2.2:5238';

  runApp(
    MyApp(
      variantApi: StaffVariantApi(baseUrl: apiBaseUrl),
      promotionApi: PromotionApi(baseUrl: apiBaseUrl),
      orderApi: OrderApi(baseUrl: apiBaseUrl),
      cartApi: CartApi(baseUrl: apiBaseUrl),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.variantApi,
    required this.promotionApi,
    required this.orderApi,
    required this.cartApi,
  });

  final StaffVariantApi variantApi;
  final PromotionApi promotionApi;
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
        variantApi: variantApi,
        promotionApi: promotionApi,
        orderApi: orderApi,
        cartApi: cartApi,
      ),
    );
  }
}

class AppNavigation extends StatefulWidget {
  const AppNavigation({
    super.key,
    required this.variantApi,
    required this.promotionApi,
    required this.orderApi,
    required this.cartApi,
  });

  final StaffVariantApi variantApi;
  final PromotionApi promotionApi;
  final OrderApi orderApi;
  final CartApi cartApi;

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  static const int mockCustomerId = 1;

  int _currentIndex = 0;

  late final List<Widget> _pages = [
    StaffVariantPage(api: widget.variantApi),
    PromotionPage(api: widget.promotionApi),
    StaffOrdersPage(api: widget.orderApi),
    CustomerOrdersPage(api: widget.orderApi, customerId: mockCustomerId),
    CustomerCartPage(api: widget.cartApi, customerId: mockCustomerId),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Variants',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_offer_outlined),
            selectedIcon: Icon(Icons.local_offer),
            label: 'Promotions',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'All Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'My Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
        ],
      ),
    );
  }
}
