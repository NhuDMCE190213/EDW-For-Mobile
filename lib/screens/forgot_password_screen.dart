import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/api_exception.dart';
import '../services/auth_api.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, required this.authApi});

  final AuthApi authApi;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _step = 1; // 1: Email, 2: OTP, 3: New Password
  bool _isCustomer = true;
  bool _loading = false;
  String _resetToken = '';
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Bước 1: Gửi mã OTP tới Email
  Future<void> _sendOtp() async {
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final message = await widget.authApi.sendForgotPasswordOtp(
        email: email,
        isCustomer: _isCustomer,
      );

      if (!mounted) return;
      setState(() {
        _step = 2;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Connection error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Bước 2: Xác thực mã OTP để nhận ResetToken
  Future<void> _verifyOtp() async {
    if (!_otpFormKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final otp = _otpController.text.trim();

      final token = await widget.authApi.verifyForgotPasswordOtp(
        email: email,
        otp: otp,
        isCustomer: _isCustomer,
      );

      if (!mounted) return;
      setState(() {
        _resetToken = token;
        _step = 3;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xác thực OTP thành công! Vui lòng nhập mật khẩu mới.'),
          backgroundColor: Colors.green,
        ),
      );
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Connection error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Gửi lại mã OTP
  Future<void> _resendOtp() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final message = await widget.authApi.sendForgotPasswordOtp(
        email: email,
        isCustomer: _isCustomer,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã gửi lại: $message'),
          backgroundColor: Colors.blue,
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

  // Bước 3: Đổi mật khẩu mới
  Future<void> _resetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final newPassword = _newPasswordController.text;

      final message = await widget.authApi.resetPasswordWithOtp(
        email: email,
        resetToken: _resetToken,
        newPassword: newPassword,
        isCustomer: _isCustomer,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );

      Navigator.pop(context, email);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Connection error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quên mật khẩu')),
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
                    color: AppTheme.brand,
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
                    _step == 1
                        ? 'Bước 1/3: Nhập email để nhận mã OTP'
                        : _step == 2
                        ? 'Bước 2/3: Nhập mã OTP 6 số từ email'
                        : 'Bước 3/3: Đặt lại mật khẩu mới',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Chọn vai trò (chỉ ở Bước 1)
                  if (_step == 1) ...[
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
                          label: Text('Nhân viên / Admin'),
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
                  ],

                  // Banner lỗi nếu có
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
                          Icon(
                            Icons.error_outline,
                            color: Colors.red.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red.shade800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ════════════════════════════════════════════════════════
                  // BƯỚC 1: NHẬP EMAIL
                  // ════════════════════════════════════════════════════════
                  if (_step == 1)
                    Form(
                      key: _emailFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: _isCustomer
                                  ? 'Email khách hàng'
                                  : 'Email nhân viên',
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
                                return 'Định dạng email không hợp lệ.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _loading ? null : _sendOtp,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.brand,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Gửi mã OTP qua Email',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    )

                  // ════════════════════════════════════════════════════════
                  // BƯỚC 2: NHẬP MÃ OTP
                  // ════════════════════════════════════════════════════════
                  else if (_step == 2)
                    Form(
                      key: _otpFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.mark_email_read,
                                  color: AppTheme.brand,
                                  size: 24,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Mã xác thực đã được gửi tới:',
                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                      Text(
                                        _emailController.text,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          TextFormField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              letterSpacing: 12,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Mã OTP (6 số)',
                              hintText: '000000',
                              prefixIcon: Icon(Icons.shield_outlined),
                              border: OutlineInputBorder(),
                              counterText: '',
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Vui lòng nhập mã OTP.';
                              }
                              if (val.trim().length != 6) {
                                return 'Mã OTP phải có đúng 6 chữ số.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          FilledButton(
                            onPressed: _loading ? null : _verifyOtp,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.brand,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Xác nhận mã OTP',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 12),

                          TextButton.icon(
                            onPressed: _loading ? null : _resendOtp,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Chưa nhận được mã? Gửi lại OTP'),
                          ),
                          TextButton(
                            onPressed: () => setState(() => _step = 1),
                            child: const Text('← Thay đổi email khác'),
                          ),
                        ],
                      ),
                    )

                  // ════════════════════════════════════════════════════════
                  // BƯỚC 3: NHẬP MẬT KHẨU MỚI
                  // ════════════════════════════════════════════════════════
                  else
                    Form(
                      key: _resetFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Email: ${_emailController.text}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
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
                                icon: Icon(
                                  _obscureNewPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () => setState(
                                  () => _obscureNewPassword =
                                      !_obscureNewPassword,
                                ),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Vui lòng nhập mật khẩu mới.';
                              }
                              if (val.length < 8) {
                                return 'Mật khẩu phải có ít nhất 8 ký tự.';
                              }
                              final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(val);
                              final hasNumber = RegExp(r'\d').hasMatch(val);
                              final hasSpecial = RegExp(
                                r'[!@#$%^&*()_+\-=\[\]{};:\x27"\\|,.<>\/?]',
                              ).hasMatch(val);
                              if (!hasLetter || !hasNumber || !hasSpecial) {
                                return 'Mật khẩu phải chứa chữ cái, số và ký tự đặc biệt.';
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
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () => setState(
                                  () => _obscureConfirmPassword =
                                      !_obscureConfirmPassword,
                                ),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Vui lòng xác nhận lại mật khẩu.';
                              }
                              if (val != _newPasswordController.text) {
                                return 'Mật khẩu xác nhận không khớp.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          FilledButton(
                            onPressed: _loading ? null : _resetPassword,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.brand,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Cập nhật mật khẩu mới',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
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
