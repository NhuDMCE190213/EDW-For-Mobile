import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'screens/admin_catalog_page.dart';
import 'screens/staff_variant_page.dart';
import 'services/admin_catalog_api.dart';
import 'services/staff_variant_api.dart';

void main() {
  final baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  final resolvedBaseUrl = baseUrl.isNotEmpty
      ? baseUrl
      : kIsWeb
      ? 'http://localhost:5238'
      : 'http://10.0.2.2:5238';
  runApp(
    MyApp(
      adminApi: AdminCatalogApi(baseUrl: resolvedBaseUrl),
      staffApi: StaffVariantApi(baseUrl: resolvedBaseUrl),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.adminApi, required this.staffApi});

  final AdminCatalogApi adminApi;
  final StaffVariantApi staffApi;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EDW Management',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE24B4A)),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFF7F7F7),
        ),
      ),
      home: ManagementHomePage(adminApi: adminApi, staffApi: staffApi),
    );
  }
}

class ManagementHomePage extends StatelessWidget {
  const ManagementHomePage({
    super.key,
    required this.adminApi,
    required this.staffApi,
  });

  final AdminCatalogApi adminApi;
  final StaffVariantApi staffApi;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('EDW Management'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.category_outlined), text: 'Categories'),
              Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Products'),
              Tab(icon: Icon(Icons.tune_outlined), text: 'Variants'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            CategoryManagementPage(api: adminApi),
            ProductManagementPage(api: adminApi),
            StaffVariantPage(api: staffApi, showAppBar: false),
          ],
        ),
      ),
    );
  }
}
