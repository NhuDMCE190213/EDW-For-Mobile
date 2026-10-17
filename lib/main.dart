import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'screens/admin_catalog_page.dart';
import 'screens/login_screen.dart';
import 'screens/promotion_page.dart';
import 'screens/staff_variant_page.dart';
import 'screens/profile_screen.dart';
import 'screens/staff_orders_page.dart';
import 'screens/admin_user_management_page.dart';
import 'services/auth_api.dart';
import 'services/admin_catalog_api.dart';
import 'services/promotion_api.dart';
import 'services/cart_api.dart';
import 'services/order_api.dart';
import 'services/staff_variant_api.dart';
import 'services/admin_user_api.dart';

void main() {
  const configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  final resolvedBaseUrl = configuredBaseUrl.isNotEmpty
      ? configuredBaseUrl
      : kIsWeb
      ? 'http://localhost:5238'
      : 'http://10.0.2.2:5238';

  runApp(
    MyApp(
      baseUrl: resolvedBaseUrl,
      authApi: AuthApi(baseUrl: resolvedBaseUrl),
      catalogApi: AdminCatalogApi(baseUrl: resolvedBaseUrl),
      variantApi: StaffVariantApi(baseUrl: resolvedBaseUrl),
      promotionApi: PromotionApi(baseUrl: resolvedBaseUrl),
      orderApi: OrderApi(baseUrl: resolvedBaseUrl),
      cartApi: CartApi(baseUrl: resolvedBaseUrl),
      adminUserApi: AdminUserApi(baseUrl: resolvedBaseUrl),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.baseUrl,
    required this.authApi,
    required this.catalogApi,
    required this.variantApi,
    required this.promotionApi,
    required this.orderApi,
    required this.cartApi,
    required this.adminUserApi,
  });
  final String baseUrl;
  final AuthApi authApi;
  final AdminCatalogApi catalogApi;
  final StaffVariantApi variantApi;
  final PromotionApi promotionApi;
  final OrderApi orderApi;
  final CartApi cartApi;
  final AdminUserApi adminUserApi;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EDW Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE24B4A)),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFF7F7F7),
        ),
      ),
      home: LoginScreen(authApi: authApi, baseUrl: baseUrl),
      routes: {
        '/home': (context) => AppNavigation(
          variantApi: variantApi,
          promotionApi: promotionApi,
          orderApi: orderApi,
          authApi: authApi,
          catalogApi: catalogApi,
          adminUserApi: adminUserApi,
          baseUrl: baseUrl,
          authToken: ModalRoute.of(context)?.settings.arguments is Map
              ? (ModalRoute.of(context)?.settings.arguments as Map)['token']
                    as String?
              : ModalRoute.of(context)?.settings.arguments as String?,
          role: ModalRoute.of(context)?.settings.arguments is Map
              ? (ModalRoute.of(context)?.settings.arguments as Map)['role']
                    as String?
              : null,
        ),
      },
    );
  }
}

class AppNavigation extends StatefulWidget {
  const AppNavigation({
    super.key,
    required this.variantApi,
    required this.promotionApi,
    required this.orderApi,
    required this.authApi,
    required this.catalogApi,
    required this.adminUserApi,
    required this.baseUrl,
    this.authToken,
    this.role,
  });

  final StaffVariantApi variantApi;
  final PromotionApi promotionApi;
  final OrderApi orderApi;
  final AuthApi authApi;
  final AdminCatalogApi catalogApi;
  final AdminUserApi adminUserApi;
  final String baseUrl;
  final String? authToken;
  final String? role;

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  int _currentIndex = 0;
  late final List<Widget> _pages;
  final _variantPageKey = GlobalKey<StaffVariantPageState>();
  final _ordersPageKey = GlobalKey<StaffOrdersPageState>();
  final _userPageKey = GlobalKey<AdminUserManagementPageState>();

  @override
  void initState() {
    super.initState();
    widget.adminUserApi.setAuthToken(widget.authToken);
    _pages = [
      StaffVariantPage(
        key: _variantPageKey,
        api: widget.variantApi,
        promotionApi: widget.promotionApi,
        authToken: widget.authToken,
      ),
      PromotionPage(api: widget.promotionApi),
      StaffOrdersPage(key: _ordersPageKey, api: widget.orderApi),
      AdminCatalogPage(api: widget.catalogApi),
      if (widget.role?.toLowerCase() == 'admin' || widget.role == '0')
        AdminUserManagementPage(key: _userPageKey, api: widget.adminUserApi),
    ];
  }

  Future<void> _refreshCurrentPage() {
    if (_currentIndex == 0) {
      return _variantPageKey.currentState?.refresh() ?? Future.value();
    }
    if (_currentIndex == 2) {
      return _ordersPageKey.currentState?.refresh() ?? Future.value();
    }
    if (_currentIndex == 4) {
      return _userPageKey.currentState?.refresh() ?? Future.value();
    }
    return Future.value();
  }

  Future<void> _openProfile() async {
    if (widget.authToken == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          token: widget.authToken!,
          role: widget.role ?? 'Staff',
          baseUrl: widget.baseUrl,
          authApi: widget.authApi,
        ),
      ),
    );
  }

  Future<void> _logout() async {
    if (widget.authToken != null) {
      try {
        await widget.authApi.logout(widget.authToken!);
      } catch (_) {}
    }
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LoginScreen(authApi: widget.authApi, baseUrl: widget.baseUrl),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0
              ? 'Product Variant Management'
              : _currentIndex == 1
              ? 'Promotion Management'
              : _currentIndex == 2
              ? 'Staff - View Orders'
              : _currentIndex == 3
              ? 'Product and Category Management'
              : 'Staff and Customer Management',
        ),
        actions: [
          IconButton(
            onPressed: _refreshCurrentPage,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: _openProfile,
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Profile',
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Variants',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.local_offer),
            label: 'Promotions',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'All Orders',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.category_outlined),
            label: 'Catalog',
          ),
          if (widget.role?.toLowerCase() == 'admin' || widget.role == '0')
            const BottomNavigationBarItem(
              icon: Icon(Icons.manage_accounts_outlined),
              label: 'Users',
            ),
        ],
      ),
    );
  }
}
