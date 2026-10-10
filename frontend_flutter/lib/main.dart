import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'services/auth_api.dart';

void main() {
  final configuredBaseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  final resolvedBaseUrl = configuredBaseUrl.isNotEmpty
      ? configuredBaseUrl
      : kIsWeb
          ? 'http://localhost:5238'
          : 'http://10.0.2.2:5238';

  final authApi = AuthApi(baseUrl: resolvedBaseUrl);

  runApp(MyApp(
    authApi: authApi,
    baseUrl: resolvedBaseUrl,
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.authApi,
    required this.baseUrl,
  });

  final AuthApi authApi;
  final String baseUrl;

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
      home: LoginScreen(
        authApi: authApi,
        baseUrl: baseUrl,
      ),
    );
  }
}

