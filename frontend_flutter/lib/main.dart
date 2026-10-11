import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'screens/promotion_page.dart';
import 'screens/staff_variant_page.dart';
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
      api: StaffVariantApi(baseUrl: apiBaseUrl),
      promotionApi: PromotionApi(baseUrl: apiBaseUrl),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.api, required this.promotionApi});

  final StaffVariantApi api;
  final PromotionApi promotionApi;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EDW Staff',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE24B4A)),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFF7F7F7),
        ),
      ),
      home: StaffAppShell(api: api, promotionApi: promotionApi),
    );
  }
}

class StaffAppShell extends StatefulWidget {
  const StaffAppShell({
    super.key,
    required this.api,
    required this.promotionApi,
  });

  final StaffVariantApi api;
  final PromotionApi promotionApi;

  @override
  State<StaffAppShell> createState() => _StaffAppShellState();
}

class _StaffAppShellState extends State<StaffAppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          StaffVariantPage(api: widget.api),
          PromotionPage(api: widget.promotionApi),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
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
        ],
      ),
    );
  }
}
