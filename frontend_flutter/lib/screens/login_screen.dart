import 'package:flutter/material.dart';

import '../models/auth_model.dart';
import '../services/auth_api.dart';
import '../services/staff_variant_api.dart';
import 'customer_home_screen.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'staff_variant_page.dart';

enum LoginRoleTab { customer, staff }

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.authApi,
    required this.baseUrl,
  });

  final AuthApi authApi;
  final String baseUrl;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  LoginRoleTab _selectedTab = LoginRoleTab.customer;
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final input = LoginInput(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        rememberMe: _rememberMe,
      );

      LoginResponse response;
      if (_selectedTab == LoginRoleTab.customer) {
        // UC-01.1: Login for Customer
        response = await widget.authApi.customerLogin(input);
      } else {
        // UC-01.2: Login for Staff
        response = await widget.authApi.staffLogin(input);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đăng nhập thành công! Chào ${response.fullName}.'),
          backgroundColor: Colors.green,
        ),
      );

      // Điều hướng sau đăng nhập theo Role
      if (_selectedTab == LoginRoleTab.customer) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerHomeScreen(
              user: response,
              authApi: widget.authApi,
              baseUrl: widget.baseUrl,
            ),
          ),
        );
      } else {
        // Chuyển sang màn hình quản lý biến thể của Staff (Code nhóm trưởng)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => StaffVariantPage(
              api: StaffVariantApi(baseUrl: widget.baseUrl),
              authToken: response.token,
              authApi: widget.authApi,
              baseUrl: widget.baseUrl,
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Lỗi kết nối: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _navigateToRegister() async {
    final registeredEmail = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => RegisterScreen(authApi: widget.authApi),
      ),
    );

    if (registeredEmail != null && registeredEmail.isNotEmpty) {
      setState(() {
        _emailController.text = registeredEmail;
        _selectedTab = LoginRoleTab.customer;
      });
    }
  }

  Future<void> _navigateToForgotPassword() async {
    final verifiedEmail = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => ForgotPasswordScreen(authApi: widget.authApi),
      ),
    );

    if (verifiedEmail != null && verifiedEmail.isNotEmpty) {
      setState(() {
        _emailController.text = verifiedEmail;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCustomer = _selectedTab == LoginRoleTab.customer;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo / Icon EDW
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE24B4A).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.devices_outlined,
                          size: 38,
                          color: Color(0xFFE24B4A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tiêu đề
                    const Text(
                      'EDW Store',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E1E),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isCustomer
                          ? 'Đăng nhập để theo dõi đơn hàng và mua sắm'
                          : 'Đăng nhập dành cho nhân viên quản lý',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Bộ chọn vai trò (Customer vs Staff)
                    SegmentedButton<LoginRoleTab>(
                      segments: const [
                        ButtonSegment(
                          value: LoginRoleTab.customer,
                          icon: Icon(Icons.person_outline),
                          label: Text('Khách hàng'),
                        ),
                        ButtonSegment(
                          value: LoginRoleTab.staff,
                          icon: Icon(Icons.badge_outlined),
                          label: Text('Nhân viên'),
                        ),
                      ],
                      selected: {_selectedTab},
                      onSelectionChanged: (newSelection) {
                        setState(() {
                          _selectedTab = newSelection.first;
                          _errorMessage = null;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Thông báo lỗi nếu có
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Ô nhập Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: isCustomer ? 'Email khách hàng' : 'Email nhân viên',
                        hintText: 'name@example.com',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập email.';
                        }
                        final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                        if (!emailRegExp.hasMatch(value.trim())) {
                          return 'Địa chỉ email không đúng định dạng.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Ô nhập Mật khẩu
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        hintText: 'Nhập mật khẩu của bạn',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mật khẩu.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),

                    // Ghi nhớ đăng nhập & Quên mật khẩu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (val) => setState(() => _rememberMe = val ?? false),
                            ),
                            const Text('Ghi nhớ', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                        TextButton(
                          onPressed: _navigateToForgotPassword,
                          child: const Text(
                            'Quên mật khẩu?',
                            style: TextStyle(
                              color: Color(0xFFE24B4A),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Nút Đăng nhập
                    FilledButton(
                      onPressed: _loading ? null : _submitLogin,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE24B4A),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              isCustomer ? 'Đăng nhập Khách hàng' : 'Đăng nhập Nhân viên',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                    const SizedBox(height: 20),

                    // Nút Đăng ký (chỉ hiện khi là Customer)
                    if (isCustomer)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Chưa có tài khoản?', style: TextStyle(color: Colors.grey.shade700)),
                          TextButton(
                            onPressed: _navigateToRegister,
                            child: const Text(
                              'Đăng ký ngay',
                              style: TextStyle(
                                color: Color(0xFFE24B4A),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          '* Tài khoản nhân viên được cấp bởi quản trị viên hệ thống.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
