import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'models/auth_model.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/promotion_page.dart';
import 'screens/staff_orders_page.dart';
import 'screens/admin_user_management_page.dart';
import 'services/auth_api.dart';
import 'screens/staff_reviews_page.dart';
import 'screens/staff_variant_page.dart';
import 'services/admin_catalog_api.dart';
import 'services/auth_api.dart';
import 'services/cart_api.dart';
import 'services/order_api.dart';
import 'services/promotion_api.dart';
import 'services/review_api.dart';
import 'services/staff_variant_api.dart';
import 'services/admin_user_api.dart';

void main() {
  const configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  final resolvedBaseUrl = configuredBaseUrl.isNotEmpty
      ? configuredBaseUrl
      : (kIsWeb || defaultTargetPlatform == TargetPlatform.windows)
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
      reviewApi: ReviewApi(baseUrl: resolvedBaseUrl),
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
    required this.reviewApi,
  });
  final String baseUrl;
  final AuthApi authApi;
  final AdminCatalogApi catalogApi;
  final StaffVariantApi variantApi;
  final PromotionApi promotionApi;
  final OrderApi orderApi;
  final CartApi cartApi;
  final AdminUserApi adminUserApi;
  final ReviewApi reviewApi;

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
        '/home': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          String? token;
          String role = 'Staff';

          if (args is LoginResponse) {
            token = args.token;
            role = args.role;
          } else if (args is Map) {
            token = args['token'] as String?;
            role = args['role'] as String? ?? 'Staff';
          } else if (args is String) {
            token = args;
          }

          return AppNavigation(
            variantApi: variantApi,
            promotionApi: promotionApi,
            orderApi: orderApi,
            authApi: authApi,
            catalogApi: catalogApi,
            adminUserApi: adminUserApi,
            reviewApi: reviewApi,
            baseUrl: baseUrl,
            authToken: token,
            role: role,
          );
        },
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
    required this.reviewApi,
    required this.baseUrl,
    this.authToken,
    this.role = 'Staff',
  });

  final StaffVariantApi variantApi;
  final PromotionApi promotionApi;
  final OrderApi orderApi;
  final AuthApi authApi;
  final AdminCatalogApi catalogApi;
  final AdminUserApi adminUserApi;
  final ReviewApi reviewApi;
  final String baseUrl;
  final String? authToken;
  final String role;

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  int _currentIndex = 0;
  late final List<Widget> _pages;
  final _variantPageKey = GlobalKey<StaffVariantPageState>();
  final _ordersPageKey = GlobalKey<StaffOrdersPageState>();
  final _userPageKey = GlobalKey<AdminUserManagementPageState>();
  final _reviewsPageKey = GlobalKey<StaffReviewsPageState>();

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
      if (widget.role.toLowerCase() == 'admin' || widget.role == '0')
        AdminUserManagementPage(key: _userPageKey, api: widget.adminUserApi),
      StaffReviewsPage(
        key: _reviewsPageKey,
        api: widget.reviewApi,
        userRole: widget.role,
      ),
    ];
  }

  Future<void> _refreshCurrentPage() {
    final currentWidget = _pages[_currentIndex];

    if (currentWidget is StaffVariantPage)
      return _variantPageKey.currentState?.refresh() ?? Future.value();
    if (currentWidget is StaffOrdersPage)
      return _ordersPageKey.currentState?.refresh() ?? Future.value();
    if (currentWidget is AdminUserManagementPage)
      return _userPageKey.currentState?.refresh() ?? Future.value();
    if (currentWidget is StaffReviewsPage)
      return _reviewsPageKey.currentState?.refresh() ?? Future.value();

    return Future.value();
  }

  Future<void> _openProfile() async {
    if (widget.authToken == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          token: widget.authToken!,
          role: widget.role,
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
          _pages[_currentIndex] is StaffVariantPage
              ? 'Product Variant Management'
              : _pages[_currentIndex] is PromotionPage
              ? 'Promotion Management'
              : _pages[_currentIndex] is StaffOrdersPage
              ? 'Staff - View Orders'
              : _pages[_currentIndex] is AdminUserManagementPage
              ? 'Staff and Customer Management'
              : 'Review Management',
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
          if (widget.role?.toLowerCase() == 'admin' || widget.role == '0')
            const BottomNavigationBarItem(
              icon: Icon(Icons.manage_accounts_outlined),
              label: 'Users',
            ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.rate_review_outlined),
            activeIcon: Icon(Icons.rate_review),
            label: 'Reviews',
          ),
        ],
      ),
    );
  }
}
