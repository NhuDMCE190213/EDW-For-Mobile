import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'models/auth_model.dart';
import 'screens/admin_category_page.dart';
import 'screens/admin_product_page.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/promotion_page.dart';
import 'screens/staff_orders_page.dart';
import 'screens/admin_user_management_page.dart';
import 'services/auth_api.dart';
import 'screens/staff_reviews_page.dart';
import 'screens/staff_variant_page.dart';
import 'services/admin_catalog_api.dart';
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
      theme: AppTheme.light(),
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

class _NavDestination {
  const _NavDestination({
    required this.title,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.page,
  });

  final String title;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget page;
}

class _AppNavigationState extends State<AppNavigation> {
  int _currentIndex = 0;
  late final List<_NavDestination> _destinations;
  final _variantPageKey = GlobalKey<StaffVariantPageState>();
  final _categoryPageKey = GlobalKey<AdminCategoryPageState>();
  final _productPageKey = GlobalKey<AdminProductPageState>();
  final _ordersPageKey = GlobalKey<StaffOrdersPageState>();
  final _userPageKey = GlobalKey<AdminUserManagementPageState>();
  final _reviewsPageKey = GlobalKey<StaffReviewsPageState>();

  bool get _isAdmin =>
      widget.role.toLowerCase() == 'admin' || widget.role == '0';

  @override
  void initState() {
    super.initState();
    widget.adminUserApi.setAuthToken(widget.authToken);
    _destinations = [
      _NavDestination(
        title: 'Product Variant Management',
        label: 'Variants',
        icon: Icons.inventory_2_outlined,
        activeIcon: Icons.inventory_2,
        page: StaffVariantPage(
          key: _variantPageKey,
          api: widget.variantApi,
          promotionApi: widget.promotionApi,
          authToken: widget.authToken,
        ),
      ),
      if (_isAdmin)
        _NavDestination(
          title: 'Product Category Management',
          label: 'Categories',
          icon: Icons.category_outlined,
          activeIcon: Icons.category,
          page: AdminCategoryPage(
            key: _categoryPageKey,
            api: widget.catalogApi,
          ),
        ),
      if (_isAdmin)
        _NavDestination(
          title: 'Product Management',
          label: 'Products',
          icon: Icons.devices_other_outlined,
          activeIcon: Icons.devices_other,
          page: AdminProductPage(
            key: _productPageKey,
            api: widget.catalogApi,
            baseUrl: widget.baseUrl,
          ),
        ),
      _NavDestination(
        title: 'Promotion Management',
        label: 'Promotions',
        icon: Icons.local_offer_outlined,
        activeIcon: Icons.local_offer,
        page: PromotionPage(api: widget.promotionApi),
      ),
      _NavDestination(
        title: 'Staff - View Orders',
        label: 'Orders',
        icon: Icons.assignment_outlined,
        activeIcon: Icons.assignment,
        page: StaffOrdersPage(key: _ordersPageKey, api: widget.orderApi),
      ),
      if (_isAdmin)
        _NavDestination(
          title: 'Staff and Customer Management',
          label: 'Users',
          icon: Icons.manage_accounts_outlined,
          activeIcon: Icons.manage_accounts,
          page: AdminUserManagementPage(
            key: _userPageKey,
            api: widget.adminUserApi,
          ),
        ),
      _NavDestination(
        title: 'Review Management',
        label: 'Reviews',
        icon: Icons.rate_review_outlined,
        activeIcon: Icons.rate_review,
        page: StaffReviewsPage(
          key: _reviewsPageKey,
          api: widget.reviewApi,
          userRole: widget.role,
        ),
      ),
    ];
  }

  Future<void> _refreshCurrentPage() {
    final page = _destinations[_currentIndex].page;

    if (page is StaffVariantPage) {
      return _variantPageKey.currentState?.refresh() ?? Future.value();
    }
    if (page is AdminProductPage) {
      return _productPageKey.currentState?.refresh() ?? Future.value();
    }
    if (page is AdminCategoryPage) {
      return _categoryPageKey.currentState?.refresh() ?? Future.value();
    }
    if (page is StaffOrdersPage) {
      return _ordersPageKey.currentState?.refresh() ?? Future.value();
    }
    if (page is AdminUserManagementPage) {
      return _userPageKey.currentState?.refresh() ?? Future.value();
    }
    if (page is StaffReviewsPage) {
      return _reviewsPageKey.currentState?.refresh() ?? Future.value();
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
        title: Text(_destinations[_currentIndex].title),
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
      body: IndexedStack(
        index: _currentIndex,
        children: _destinations.map((d) => d.page).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.activeIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}
