import 'package:flutter/material.dart';

import '../models/admin_catalog.dart';
import '../services/admin_catalog_api.dart';

/// Trang quản lý Product Category (chỉ Admin).
/// Dùng lại AdminCatalogApi + AdminCategory, không đổi API/model.
class AdminCategoryPage extends StatefulWidget {
  const AdminCategoryPage({super.key, required this.api});

  final AdminCatalogApi api;

  @override
  State<AdminCategoryPage> createState() => AdminCategoryPageState();
}

class AdminCategoryPageState extends State<AdminCategoryPage> {
  final _search = TextEditingController();
  List<AdminCategory> _categories = [];
  bool _loading = true;
  bool _showDeleted = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.api.getCategories();
      if (!mounted) return;
      setState(() => _categories = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<AdminCategory> get _filtered {
    final q = _search.text.trim().toLowerCase();
    return _categories.where((c) {
      if (!_showDeleted && c.isDeleted) return false;
      return q.isEmpty || c.name.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _openEditor([AdminCategory? category]) async {
    final controller = TextEditingController(text: category?.name ?? '');
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(category == null ? 'Add category' : 'Edit category'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Category name *',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Category name is required'
                : null,
            onFieldSubmitted: (_) {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final name = controller.text.trim();
    controller.dispose();
    if (saved != true) return;

    try {
      if (category == null) {
        await widget.api.createCategory(CategoryInput(name: name));
        _toast('Category created.');
      } else {
        await widget.api.updateCategory(
          CategoryInput(id: category.id, name: name),
        );
        _toast('Category updated.');
      }
      await refresh();
    } catch (e) {
      _toast(e.toString(), error: true);
    }
  }

  Future<void> _delete(AdminCategory category) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text('"${category.name}" will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.api.deleteCategory(category.id);
      _toast('Category deleted.');
      await refresh();
    } catch (e) {
      _toast(e.toString(), error: true);
    }
  }

  String _date(DateTime? d) {
    if (d == null) return '-';
    final l = d.toLocal();
    return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}/${l.year}';
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Add category'),
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search category...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(_search.clear),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${items.length} categories',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const Spacer(),
                FilterChip(
                  label: const Text('Show deleted'),
                  selected: _showDeleted,
                  onSelected: (v) => setState(() => _showDeleted = v),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 48, color: scheme.error),
                    const SizedBox(height: 8),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Column(
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 56,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No categories found',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
            else
              ...items.map(
                (c) => Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: c.isDeleted
                          ? Colors.grey.shade200
                          : scheme.primary.withValues(alpha: 0.12),
                      foregroundColor:
                          c.isDeleted ? Colors.grey : scheme.primary,
                      child: const Icon(Icons.category_outlined),
                    ),
                    title: Text(
                      c.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        decoration:
                            c.isDeleted ? TextDecoration.lineThrough : null,
                        color: c.isDeleted ? Colors.grey : null,
                      ),
                    ),
                    subtitle: Text(
                      'ID ${c.id} • Updated ${_date(c.updatedAt ?? c.createdAt)}'
                      '${c.isDeleted ? ' • Deleted' : ''}',
                    ),
                    trailing: c.isDeleted
                        ? null
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Edit',
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _openEditor(c),
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () => _delete(c),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
