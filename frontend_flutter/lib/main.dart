import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'screens/staff_variant_page.dart';
import 'services/staff_variant_api.dart';

void main() {
  final baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  runApp(MyApp(
    api: StaffVariantApi(
      baseUrl: baseUrl.isNotEmpty
          ? baseUrl
          : kIsWeb
              ? 'http://localhost:5238'
              : 'http://10.0.2.2:5238',
    ),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.api});

  final StaffVariantApi api;

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
      home: StaffVariantPage(api: api),
    );
  }
}
