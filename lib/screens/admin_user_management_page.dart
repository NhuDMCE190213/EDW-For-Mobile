import 'package:flutter/material.dart';

import '../models/admin_user.dart';
import '../services/admin_user_api.dart';

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key, required this.api});

  final AdminUserApi api;

  @override
  AdminUserManagementPageState createState() => AdminUserManagementPageState();
}

class AdminUserManagementPageState extends State<AdminUserManagementPage> {
  int _tab = 0;
  List<AdminUser> _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> refresh() => _load();

  Future<void> _load() async {
    final tab = _tab;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = tab == 0
          ? await widget.api.getStaff()
          : await widget.api.getCustomers();
      if (!mounted) return;
      if (tab != _tab) return;
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      if (tab != _tab) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _create() async {
    final tab = _tab;
    final input = await showDialog<CreateAdminUserInput>(
      context: context,
      builder: (_) => _CreateUserDialog(isCustomer: tab == 1),
    );
    if (input == null) return;
    try {
      if (tab == 0) {
        await widget.api.createStaff(input);
      } else {
        await widget.api.createCustomer(input);
      }
      await _load();
      _message('${tab == 0 ? 'Staff' : 'Customer'} created.');
    } catch (error) {
      _message(error.toString(), error: true);
    }
  }

  Future<void> _toggle(AdminUser user) async {
    final tab = _tab;
    try {
      if (tab == 0) {
        await widget.api.setStaffActive(user.id, !user.isActive);
      } else {
        await widget.api.setCustomerActive(user.id, !user.isActive);
      }
      await _load();
      _message(user.isActive ? 'User disabled.' : 'User enabled.');
    } catch (error) {
      _message(error.toString(), error: true);
    }
  }

  void _message(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? Colors.red.shade700 : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                      value: 0,
                      label: Text('Staff'),
                      icon: Icon(Icons.badge_outlined),
                    ),
                    ButtonSegment(
                      value: 1,
                      label: Text('Customers'),
                      icon: Icon(Icons.people_outline),
                    ),
                  ],
                  selected: {_tab},
                  onSelectionChanged: (selected) {
                    setState(() => _tab = selected.first);
                    _load();
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _loading ? null : _create,
                icon: const Icon(Icons.add),
                label: Text(_tab == 0 ? 'Create staff' : 'Create customer'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('Try again')),
          ],
        ),
      );
    }
    if (_users.isEmpty) return const Center(child: Text('No users found.'));
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        itemCount: _users.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, index) {
          final user = _users[index];
          return ListTile(
            leading: CircleAvatar(
              child: Text(
                user.fullName.isEmpty ? '?' : user.fullName[0].toUpperCase(),
              ),
            ),
            title: Text(user.fullName.isEmpty ? '(No name)' : user.fullName),
            subtitle: Text(
              [
                user.email,
                if (user.phoneNumber?.isNotEmpty == true) user.phoneNumber!,
              ].join(' • '),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Chip(
                  label: Text(user.isActive ? 'Active' : 'Disabled'),
                  avatar: Icon(
                    user.isActive ? Icons.check : Icons.block,
                    size: 16,
                  ),
                  backgroundColor: user.isActive
                      ? Colors.green.shade50
                      : Colors.grey.shade200,
                ),
                IconButton(
                  onPressed: () => _toggle(user),
                  icon: Icon(
                    user.isActive
                        ? Icons.person_off_outlined
                        : Icons.person_add_alt_1_outlined,
                  ),
                  tooltip: user.isActive ? 'Disable' : 'Enable',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CreateUserDialog extends StatefulWidget {
  const _CreateUserDialog({required this.isCustomer});

  final bool isCustomer;

  @override
  State<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<_CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      CreateAdminUserInput(
        fullName: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        phoneNumber: widget.isCustomer ? _phone.text.trim() : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.isCustomer ? 'Create customer' : 'Create staff'),
    content: SizedBox(
      width: 420,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _field(_name, 'Full name'),
              _field(
                _email,
                'Email',
                keyboard: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Required';
                  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                          .hasMatch(value.trim())
                      ? null
                      : 'Invalid email';
                },
              ),
              if (widget.isCustomer)
                _field(_phone, 'Phone number', keyboard: TextInputType.phone),
              _field(
                _password,
                'Password',
                obscure: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (value.length < 8) return 'At least 8 characters';
                  if (!RegExp(r'[A-Za-z]').hasMatch(value) ||
                      !RegExp(r'\d').hasMatch(value) ||
                      !RegExp(r'''[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>/?]''')
                          .hasMatch(value)) {
                    return 'Must contain a letter, number and symbol';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Create')),
    ],
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = true,
    bool obscure = false,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator:
          validator ??
          (required
              ? (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null
              : null),
    ),
  );
}
