import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'screens/admin_catalog_page.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/staff_orders_page.dart';
import 'screens/staff_variant_page.dart';
import 'services/admin_catalog_api.dart';
import 'services/auth_api.dart';
import 'services/cart_api.dart';
import 'services/order_api.dart';
import 'services/staff_variant_api.dart';

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
      variantApi: StaffVariantApi(baseUrl: resolvedBaseUrl),
      orderApi: OrderApi(baseUrl: resolvedBaseUrl),
      cartApi: CartApi(baseUrl: resolvedBaseUrl),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.baseUrl,
    required this.adminApi,
    required this.authApi,
    required this.variantApi,
    required this.orderApi,
    required this.cartApi,
  });

  final String baseUrl;
  final AdminCatalogApi adminApi;
  final AuthApi authApi;
  final StaffVariantApi variantApi;
  final OrderApi orderApi;
  final CartApi cartApi;

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
          orderApi: orderApi,
          authApi: authApi,
          baseUrl: baseUrl,
          authToken: ModalRoute.of(context)?.settings.arguments as String?,
        ),
      },
    );
  }
}

class AppNavigation extends StatefulWidget {
  const AppNavigation({
    super.key,
    required this.adminApi,
    required this.variantApi,
    required this.orderApi,
    required this.authApi,
    required this.baseUrl,
    this.authToken,
  });

  final AdminCatalogApi adminApi;
  final StaffVariantApi variantApi;
  final OrderApi orderApi;
  final AuthApi authApi;
  final String baseUrl;
  final String? authToken;

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  int _currentIndex = 0;
  late final List<Widget> _pages;
  final _variantPageKey = GlobalKey<StaffVariantPageState>();
  final _ordersPageKey = GlobalKey<StaffOrdersPageState>();

  @override
  void initState() {
    super.initState();
    _pages = [
      StaffVariantPage(
        key: _variantPageKey,
        api: widget.variantApi,
        authToken: widget.authToken,
      ),
      StaffOrdersPage(key: _ordersPageKey, api: widget.orderApi),
    ];
  }

  Future<void> _refreshCurrentPage() {
    return _currentIndex == 0
        ? _variantPageKey.currentState!.refresh()
        : _ordersPageKey.currentState!.refresh();
  }

  Future<void> _openProfile() async {
    if (widget.authToken == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          token: widget.authToken!,
          role: 'Staff',
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
    final title = _currentIndex == 1
        ? 'Product Variant Management'
        : 'Staff - View Orders';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0
              ? 'Product Variant Management'
              : 'Staff - View Orders',
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Variants',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'All Orders',
          ),
        ],
      ),
    );
  }
}
