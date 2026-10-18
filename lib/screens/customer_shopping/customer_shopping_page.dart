//Tiêu Gia Huy
import 'package:flutter/material.dart';

import '../../services/customer_shopping_api.dart';
import 'product_catalog_view.dart';
import 'my_cart_view.dart';

class CustomerShoppingEntry extends StatelessWidget {
  const CustomerShoppingEntry({
    super.key,
    required this.baseUrl,
    required this.token,
    required this.customerId,
  });
  final String baseUrl, token;
  final int customerId;
  @override
  Widget build(BuildContext context) => PopupMenuButton<int>(
    tooltip: 'Shopping',
    icon: const Icon(Icons.storefront_outlined),
    onSelected: (tab) => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CustomerShoppingPage(
          baseUrl: baseUrl,
          token: token,
          customerId: customerId,
          initialTab: tab,
        ),
      ),
    ),
    itemBuilder: (_) => const [
      PopupMenuItem(value: 0, child: Text('Products')),
      PopupMenuItem(value: 1, child: Text('Manage my cart')),
    ],
  );
}

class CustomerShoppingPage extends StatefulWidget {
  const CustomerShoppingPage({
    super.key,
    required this.baseUrl,
    required this.token,
    this.customerId = 0,
    this.initialTab = 0,
  });
  final String baseUrl, token;
  final int customerId;
  final int initialTab;
  @override
  State<CustomerShoppingPage> createState() => _CustomerShoppingPageState();
}

class _CustomerShoppingPageState extends State<CustomerShoppingPage> {
  late final CustomerShoppingApi _api;
  late int _tab;
  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    _api = CustomerShoppingApi(
      baseUrl: widget.baseUrl,
      token: widget.token,
      customerId: widget.customerId,
    );
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_tab == 0 ? 'Products' : 'My cart')),
    body: _tab == 0
        ? ProductCatalogView(api: _api, customerId: widget.customerId)
        : MyCartView(api: _api),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _tab,
      onDestinationSelected: (index) => setState(() => _tab = index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.storefront_outlined),
          label: 'Products',
        ),
        NavigationDestination(
          icon: Icon(Icons.shopping_cart_outlined),
          label: 'My cart',
        ),
      ],
    ),
  );
}
