//Tiêu Gia Huy
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:frontend_flutter/models/customer_shopping.dart';
import 'package:frontend_flutter/services/customer_shopping_api.dart';
import 'package:frontend_flutter/screens/customer_shopping/my_cart_view.dart';
import 'package:frontend_flutter/screens/customer_shopping/product_catalog_view.dart';

Map<String, dynamic> cartJson({int quantity = 2}) => {
  'cartItemId': 7,
  'productName': 'Test phone',
  'sku': 'PHONE-BLACK',
  'quantity': quantity,
  'stockQuantity': 3,
  'unitPrice': 900,
  'totalPrice': quantity * 900,
};
Map<String, dynamic> productJson(int id, String name, String category) => {
  'productId': id,
  'productName': name,
  'brand': 'EDW',
  'categoryName': category,
  'variants': [
    {
      'productVariantId': 'v$id',
      'sku': 'SKU$id',
      'color': 'Black',
      'price': 900,
      'stockQuantity': 3,
    },
  ],
};
CustomerShoppingApi apiWith(
  Future<http.Response> Function(http.Request) handle,
) => CustomerShoppingApi(
  baseUrl: 'https://example.test',
  token: 'customer-token',
  client: MockClient(handle),
);

void main() {
  test(
    'quantity request uses bearer identity and a quantity-only body',
    () async {
      final api = apiWith((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/customer/shopping/cart/7/quantity');
        expect(request.url.query, isEmpty);
        expect(request.headers['Authorization'], 'Bearer customer-token');
        expect(jsonDecode(request.body), {'quantity': 3});
        return http.Response('', 204);
      });
      addTearDown(api.close);
      await api.updateQuantity(7, 3);
      await expectLater(api.updateQuantity(7, 0), throwsException);
    },
  );

  test(
    'cart prices preserve backend discounts and relative image URLs',
    () async {
      final api = apiWith(
        (_) async => http.Response(jsonEncode([cartJson()]), 200),
      );
      addTearDown(api.close);
      final items = await api.getCart();
      expect(items.single.totalPrice, 1800);
      expect(
        api.imageUrl('/uploads/phone.png'),
        'https://example.test/uploads/phone.png',
      );
      expect(api.imageUrl('javascript:alert(1)'), isNull);
    },
  );

  testWidgets(
    'catalog search, category filter and details work at mobile width',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = apiWith(
        (_) async => http.Response(
          jsonEncode([
            productJson(1, 'Phone Alpha', 'Phones'),
            productJson(2, 'Laptop Beta', 'Laptops'),
          ]),
          200,
        ),
      );
      addTearDown(api.close);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProductCatalogView(api: api)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Phone Alpha'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'beta');
      await tester.pumpAndSettle();
      expect(find.text('Phone Alpha'), findsNothing);
      await tester.tap(find.text('Laptop Beta'));
      await tester.pumpAndSettle();
      expect(find.text('SKU2 - Black'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '');
      await tester.tap(find.text('All categories'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Phones').last);
      await tester.pumpAndSettle();
      expect(find.text('Phone Alpha'), findsOneWidget);
      expect(find.text('Laptop Beta'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('quantity editor rejects zero and stock overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<int>(
                context: context,
                builder: (_) =>
                    CartQuantityDialog(item: ShopCartItem.fromJson(cartJson())),
              ),
              child: const Text('Edit'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '0');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a whole number of at least 1.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '4');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Only 3 available.'), findsOneWidget);
  });

  testWidgets('quantity updates reload totals, removal needs confirmation', (
    tester,
  ) async {
    var quantity = 2, deletes = 0;
    final api = apiWith((request) async {
      if (request.method == 'PUT') {
        quantity = (jsonDecode(request.body) as Map)['quantity'] as int;
        return http.Response('', 204);
      }
      if (request.method == 'DELETE') {
        deletes++;
        return http.Response('', 204);
      }
      return http.Response(
        jsonEncode(deletes == 0 ? [cartJson(quantity: quantity)] : []),
        200,
      );
    });
    addTearDown(api.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MyCartView(api: api)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Total: 1,800 VND'), findsOneWidget);
    await tester.tap(find.byTooltip('Increase quantity'));
    await tester.pumpAndSettle();
    expect(find.text('Total: 2,700 VND'), findsOneWidget);
    expect(
      tester.widget<IconButton>(find.byWidgetPredicate((widget) =>
        widget is IconButton && widget.tooltip == 'Increase quantity')).onPressed,
      isNull,
    );
    await tester.tap(find.byTooltip('Remove product'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(deletes, 0);
    await tester.tap(find.byTooltip('Remove product'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(deletes, 1);
    expect(find.text('Your cart is empty.'), findsOneWidget);
  });

  testWidgets('failed update preserves cart and displays server message', (
    tester,
  ) async {
    final api = apiWith(
      (request) async => request.method == 'PUT'
          ? http.Response('{"message":"Only 2 items are available."}', 409)
          : http.Response(jsonEncode([cartJson()]), 200),
    );
    addTearDown(api.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MyCartView(api: api)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Increase quantity'));
    await tester.pumpAndSettle();
    expect(find.text('Only 2 items are available.'), findsOneWidget);
    expect(find.text('Total: 1,800 VND'), findsOneWidget);
  });

  testWidgets(
    'late response after closing cart does not update disposed state',
    (tester) async {
      final pending = Completer<http.Response>();
      final api = apiWith((_) => pending.future);
      addTearDown(api.close);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MyCartView(api: api)),
        ),
      );
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      pending.complete(http.Response('[]', 200));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [320.0, 1280.0]) {
    testWidgets('cart has no layout overflow at width $width', (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = apiWith(
        (_) async => http.Response(
          jsonEncode([
            {
              ...cartJson(),
              'productName': 'A very long product name with RAM and storage specifications',
            },
          ]),
          200,
        ),
      );
      addTearDown(api.close);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MyCartView(api: api)),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
