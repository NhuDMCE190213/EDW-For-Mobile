import 'package:flutter/material.dart';

import '../services/auth_api.dart';
import '../services/staff_variant_api.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, required this.authApi});

  final AuthApi authApi;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isCustomer = true;
  bool _emailVerified = false;
  bool _loading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _verifyEmail() async {
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      if (_isCustomer) {
        await widget.authApi.verifyCustomerEmail(email);
      } else {
        await widget.authApi.verifyStaffEmail(email);
      }

      if (!mounted) return;
      setState(() {
        _emailVerified = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xác thực email thành công! Vui lòng nhập mật khẩu mới.'),
          backgroundColor: Colors.green,
        ),
      );
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Lỗi kết nối: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final newPassword = _newPasswordController.text;

      if (_isCustomer) {
        await widget.authApi.resetCustomerPassword(email, newPassword);
      } else {
        await widget.authApi.resetStaffPassword(email, newPassword);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đặt lại mật khẩu thành công! Vui lòng đăng nhập lại.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, email);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Lỗi kết nối: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quên mật khẩu'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.lock_reset,
                    size: 64,
                    color: Color(0xFFE24B4A),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Khôi phục mật khẩu',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E1E),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _emailVerified
                        ? 'Bước 2/2: Nhập mật khẩu mới cho tài khoản'
                        : 'Bước 1/2: Nhập email đã đăng ký để xác thực',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Chọn vai trò (chỉ cho phép chọn khi chưa verify email)
                  if (!_emailVerified)
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: true,
                          icon: Icon(Icons.person_outline),
                          label: Text('Khách hàng'),
                        ),
                        ButtonSegment(
                          value: false,
                          icon: Icon(Icons.badge_outlined),
                          label: Text('Nhân viên'),
                        ),
                      ],
                      selected: {_isCustomer},
                      onSelectionChanged: (set) {
                        setState(() {
                          _isCustomer = set.first;
                          _errorMessage = null;
                        });
                      },
                    ),
                  const SizedBox(height: 20),

                  // Banner lỗi
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

                  // BƯỚC 1: XÁC THỰC EMAIL
                  if (!_emailVerified)
                    Form(
                      key: _emailFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: _isCustomer ? 'Email khách hàng' : 'Email nhân viên',
                              hintText: 'name@example.com',
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: const OutlineInputBorder(),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Vui lòng nhập địa chỉ email.';
                              }
                              final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                              if (!regex.hasMatch(val.trim())) {
                                return 'Email không đúng định dạng.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _loading ? null : _verifyEmail,
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
                                : const Text(
                                    'Xác thực Email',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ],
                      ),
                    )
                  // BƯỚC 2: NHẬP MẬT KHẨU MỚI
                  else
                    Form(
                      key: _resetFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Hiển thị email đã xác thực
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Email: ${_emailController.text}',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _newPasswordController,
                            obscureText: _obscureNewPassword,
                            decoration: InputDecoration(
                              labelText: 'Mật khẩu mới',
                              hintText: 'Tối thiểu 8 ký tự, gồm chữ, số & ký tự đặc biệt',
                              prefixIcon: const Icon(Icons.lock_outline),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureNewPassword ? Icons.visibility_off : Icons.visibility),
                                onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Vui lòng nhập mật khẩu mới.';
                              if (val.length < 8) return 'Mật khẩu phải từ 8 ký tự trở lên.';
                              final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(val);
                              final hasNumber = RegExp(r'\d').hasMatch(val);
                              final hasSpecial = RegExp(r'[!@#$%^&*()_+\-=\[\]{};:\x27"\\|,.<>\/?]').hasMatch(val);
                              if (!hasLetter || !hasNumber || !hasSpecial) {
                                return 'Cần gồm chữ cái, số và ký tự đặc biệt.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'Xác nhận mật khẩu mới',
                              hintText: 'Nhập lại mật khẩu mới',
                              prefixIcon: const Icon(Icons.lock_reset_outlined),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Vui lòng xác nhận mật khẩu.';
                              if (val != _newPasswordController.text) return 'Mật khẩu xác nhận không khớp.';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          FilledButton(
                            onPressed: _loading ? null : _resetPassword,
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
                                : const Text(
                                    'Cập nhật mật khẩu mới',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Quay lại Đăng nhập'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
