import 'package:flutter/material.dart';

import '../models/profile_model.dart';
import '../services/auth_api.dart';
import '../services/profile_api.dart';
import '../services/staff_variant_api.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.token,
    required this.role,
    required this.baseUrl,
    this.authApi,
  });

  final String token;
  final String role;
  final String baseUrl;
  final AuthApi? authApi;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileApi _profileApi;
  UserProfile? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _profileApi = ProfileApi(baseUrl: widget.baseUrl);
    _loadProfile();
  }

  // UC-05.1: View Profile
  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final profile = await _profileApi.getProfile(widget.token);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tải thông tin hồ sơ: $e';
        _loading = false;
      });
    }
  }

  // UC-05.2: Edit Profile
  Future<void> _showEditProfileDialog() async {
    if (_profile == null) return;

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: _profile!.fullName);
    final phoneController = TextEditingController(text: _profile!.phoneNumber ?? '');
    bool updating = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Chỉnh sửa thông tin'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Họ và tên',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Vui lòng nhập họ tên.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    if (widget.role.toLowerCase() == 'customer')
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Số điện thoại',
                          prefixIcon: Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Vui lòng nhập số điện thoại.';
                          return null;
                        },
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: updating ? null : () => Navigator.pop(ctx),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: updating
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => updating = true);
                        final messenger = ScaffoldMessenger.of(context);

                        try {
                          await _profileApi.updateProfile(
                            widget.token,
                            fullName: nameController.text.trim(),
                            phoneNumber: phoneController.text.trim(),
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Cập nhật thông tin thành công!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _loadProfile();
                        } on ApiException catch (e) {
                          setDialogState(() => updating = false);
                          messenger.showSnackBar(
                            SnackBar(content: Text(e.message), backgroundColor: Colors.red),
                          );
                        } catch (e) {
                          setDialogState(() => updating = false);
                          messenger.showSnackBar(
                            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                          );
                        }
                      },
                child: updating
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Lưu thay đổi'),
              ),
            ],
          );
        },
      ),
    );

    nameController.dispose();
    phoneController.dispose();
  }

  // UC-05.3: Change Password
  Future<void> _showChangePasswordDialog() async {
    final formKey = GlobalKey<FormState>();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool updating = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Đổi mật khẩu'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu mới',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Vui lòng nhập mật khẩu mới.';
                        if (val.length < 8) return 'Tối thiểu 8 ký tự.';
                        final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(val);
                        final hasNumber = RegExp(r'\d').hasMatch(val);
                        final hasSpecial = RegExp(r'[!@#$%^&*()_+\-=\[\]{};:\x27"\\|,.<>\/?]').hasMatch(val);
                        if (!hasLetter || !hasNumber || !hasSpecial) {
                          return 'Cần có chữ cái, số và ký tự đặc biệt.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Xác nhận mật khẩu mới',
                        prefixIcon: const Icon(Icons.lock_reset_outlined),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Vui lòng xác nhận mật khẩu.';
                        if (val != newPasswordController.text) return 'Mật khẩu không trùng khớp.';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: updating ? null : () => Navigator.pop(ctx),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: updating
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => updating = true);
                        final messenger = ScaffoldMessenger.of(context);

                        try {
                          await _profileApi.changePassword(
                            widget.token,
                            newPassword: newPasswordController.text,
                            confirmPassword: confirmPasswordController.text,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Đổi mật khẩu thành công!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } on ApiException catch (e) {
                          setDialogState(() => updating = false);
                          messenger.showSnackBar(
                            SnackBar(content: Text(e.message), backgroundColor: Colors.red),
                          );
                        } catch (e) {
                          setDialogState(() => updating = false);
                          messenger.showSnackBar(
                            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                          );
                        }
                      },
                child: updating
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Cập nhật'),
              ),
            ],
          );
        },
      ),
    );

    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  // UC-02: Logout
  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE24B4A)),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    if (widget.authApi != null) {
      try {
        await widget.authApi!.logout(widget.token);
      } catch (_) {}
    }

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          authApi: widget.authApi ?? AuthApi(baseUrl: widget.baseUrl),
          baseUrl: widget.baseUrl,
        ),
      ),
      (route) => false,
    );
  }

  String _formatRole(String role) {
    switch (role) {
      case '0':
      case 'Admin':
        return 'Quản trị viên';
      case '1':
      case 'Staff':
        return 'Nhân viên';
      case '2':
      case 'Customer':
        return 'Khách hàng';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadProfile,
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _loadProfile,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Card Avatar & Tên
                      Card(
                        elevation: 0,
                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.25),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 42,
                                backgroundColor: const Color(0xFFE24B4A),
                                child: Text(
                                  _profile!.fullName.isNotEmpty
                                      ? _profile!.fullName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _profile!.fullName,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _profile!.email,
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              Chip(
                                label: Text(
                                  'Vai trò: ${_formatRole(widget.role)}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                backgroundColor: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Chi tiết thông tin
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.person_outline),
                              title: const Text('Họ và tên'),
                              subtitle: Text(_profile!.fullName),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.email_outlined),
                              title: const Text('Email'),
                              subtitle: Text(_profile!.email),
                            ),
                            if (_profile!.phoneNumber != null && _profile!.phoneNumber!.isNotEmpty) ...[
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(Icons.phone_outlined),
                                title: const Text('Số điện thoại'),
                                subtitle: Text(_profile!.phoneNumber!),
                              ),
                            ],
                            if (_profile!.points != null) ...[
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(Icons.stars_outlined, color: Colors.amber),
                                title: const Text('Điểm tích lũy'),
                                subtitle: Text('${_profile!.points} điểm'),
                              ),
                            ],
                            if (_profile!.createdAt != null) ...[
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(Icons.calendar_today_outlined),
                                title: const Text('Ngày tham gia'),
                                subtitle: Text(
                                  '${_profile!.createdAt!.day}/${_profile!.createdAt!.month}/${_profile!.createdAt!.year}',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Nút hành động
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _showEditProfileDialog,
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Sửa hồ sơ'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _showChangePasswordDialog,
                              icon: const Icon(Icons.key_outlined),
                              label: const Text('Đổi mật khẩu'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Nút Đăng xuất
                      FilledButton.icon(
                        onPressed: _handleLogout,
                        icon: const Icon(Icons.logout),
                        label: const Text('Đăng xuất'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
