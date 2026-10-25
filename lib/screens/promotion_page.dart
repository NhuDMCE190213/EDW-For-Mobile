import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/promotion.dart';
import '../services/promotion_api.dart';

class PromotionPage extends StatefulWidget {
  const PromotionPage({super.key, required this.api});

  final PromotionApi api;

  @override
  State<PromotionPage> createState() => _PromotionPageState();
}

class _PromotionPageState extends State<PromotionPage> {
  final _searchController = TextEditingController();
  PromotionListResult? _result;
  bool _loading = true;
  bool _actionInProgress = false;
  String? _error;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool spinner = true, int? previousPage}) async {
    if (spinner) setState(() => _loading = true);
    try {
      final result = await widget.api.list(
        searchTerm: _searchController.text,
        page: _page,
      );
      if (!mounted) return;
      if (result.items.isEmpty && _page > 1) {
        _page = math.max(1, math.min(result.totalPages, _page - 1));
        await _load(spinner: false);
        return;
      }
      setState(() {
        _result = result;
        _error = null;
        _loading = false;
        _actionInProgress = false;
      });
    } catch (error) {
      if (!mounted) return;
      if (previousPage != null) _page = previousPage;
      setState(() {
        _error = error.toString();
        _loading = false;
        _actionInProgress = false;
      });
    }
  }

  Future<void> _edit([Promotion? promotion]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) =>
          PromotionEditorDialog(api: widget.api, promotion: promotion),
    );
    if (saved == true) _load(spinner: false);
  }

  Future<void> _delete(Promotion promotion) async {
    if (_actionInProgress) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete promotion?'),
        content: Text(
          'Delete "${promotion.name}"? This will mark the promotion as deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _actionInProgress = true);
    try {
      await widget.api.delete(promotion.id);
      _message('Promotion soft-deleted.');
      _load(spinner: false);
    } catch (error) {
      if (mounted) setState(() => _actionInProgress = false);
      _message(error.toString(), error: true);
    }
  }

  Future<void> _toggleDisabled(Promotion promotion) async {
    if (_actionInProgress) return;
    final disable = !promotion.isDisabled;
    setState(() => _actionInProgress = true);
    try {
      await widget.api.update(
        promotion.id,
        PromotionInput.fromPromotion(promotion, isDisable: disable),
      );
      _message(disable ? 'Promotion disabled.' : 'Promotion enabled.');
      _load(spinner: false);
    } catch (error) {
      if (mounted) setState(() => _actionInProgress = false);
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
    final result = _result;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promotion Management'),
        actions: [
          IconButton(
            onPressed: _loading || _actionInProgress ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildToolbar(),
            const SizedBox(height: 12),
            if (result != null) _buildStats(result),
            const SizedBox(height: 12),
            Expanded(child: _buildContent(result)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading || _actionInProgress ? null : _edit,
        icon: const Icon(Icons.add),
        label: const Text('Add promotion'),
      ),
    );
  }

  Widget _buildToolbar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onSubmitted: (_) {
              _page = 1;
              _load();
            },
            decoration: InputDecoration(
              labelText: 'Search promotion',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: () {
                  _searchController.clear();
                  _page = 1;
                  _load();
                },
                icon: const Icon(Icons.clear),
              ),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: () {
            _page = 1;
            _load();
          },
          icon: const Icon(Icons.search),
          tooltip: 'Search',
        ),
      ],
    );
  }

  Widget _buildStats(PromotionListResult result) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          _StatCard(
            'Total',
            result.totalCount,
            Colors.blue,
            Icons.sell_outlined,
          ),
          _StatCard(
            'Active',
            result.activeCount,
            Colors.green,
            Icons.check_circle_outline,
          ),
          _StatCard(
            'Upcoming',
            result.upcomingCount,
            Colors.orange,
            Icons.schedule_outlined,
          ),
          _StatCard(
            'Expired/Disabled',
            result.expiredCount,
            Colors.red,
            Icons.history,
          ),
        ];
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: cards
              .map(
                (card) => SizedBox(
                  width: constraints.maxWidth < 600
                      ? (constraints.maxWidth - 8) / 2
                      : 180,
                  child: card,
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildContent(PromotionListResult? result) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null && (result == null || result.items.isEmpty)) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('Try again')),
          ],
        ),
      );
    }
    if (result == null || result.items.isEmpty) {
      return const Center(child: Text('No promotion data yet.'));
    }
    return Column(
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => constraints.maxWidth < 800
                ? ListView.separated(
                    itemCount: result.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, index) => _PromotionCard(
                      promotion: result.items[index],
                      onEdit: result.items[index].isDeleted
                          ? null
                          : () => _edit(result.items[index]),
                      onDelete: () => _delete(result.items[index]),
                      onToggleDisabled: () =>
                          _toggleDisabled(result.items[index]),
                    ),
                  )
                : SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('NAME')),
                            DataColumn(label: Text('TYPE / VALUE')),
                            DataColumn(label: Text('STOCK')),
                            DataColumn(label: Text('DURATION')),
                            DataColumn(label: Text('STATUS')),
                            DataColumn(label: Text('ACTIONS')),
                          ],
                          rows: result.items
                              .map(
                                (promotion) => DataRow(
                                  cells: [
                                    DataCell(Text(promotion.name)),
                                    DataCell(Text(_value(promotion))),
                                    DataCell(
                                      Text(
                                        promotion.isReservedStock
                                            ? '${promotion.maxReservedStock ?? 0}'
                                            : 'Unlimited',
                                      ),
                                    ),
                                    DataCell(Text(_duration(promotion))),
                                    DataCell(
                                      _StatusBadge(status: promotion.status),
                                    ),
                                    DataCell(
                                      Row(
                                        children: [
                                          IconButton(
                                            onPressed: promotion.isDeleted
                                                ? null
                                                : () => _toggleDisabled(
                                                    promotion,
                                                  ),
                                            icon: Icon(
                                              promotion.isDisabled
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                        .visibility_off_outlined,
                                            ),
                                            tooltip: promotion.isDisabled
                                                ? 'Enable'
                                                : 'Disable',
                                          ),
                                          IconButton(
                                            onPressed: promotion.isDeleted
                                                ? null
                                                : () => _edit(promotion),
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                            ),
                                            tooltip: 'Edit',
                                          ),
                                          IconButton(
                                            onPressed: promotion.isDeleted
                                                ? null
                                                : () => _delete(promotion),
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                            ),
                                            tooltip: 'Delete',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        _buildPagination(result),
      ],
    );
  }

  Widget _buildPagination(PromotionListResult result) {
    final totalPages = result.totalPages;
    if (totalPages <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _page > 1 && !_loading && !_actionInProgress
                ? () {
                    final previousPage = _page;
                    setState(() => _page--);
                    _load(previousPage: previousPage);
                  }
                : null,
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous page',
          ),
          Text('Page $_page of $totalPages'),
          IconButton(
            onPressed: _page < totalPages && !_loading && !_actionInProgress
                ? () {
                    final previousPage = _page;
                    setState(() => _page++);
                    _load(previousPage: previousPage);
                  }
                : null,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next page',
          ),
        ],
      ),
    );
  }

  String _value(Promotion promotion) =>
      promotion.type == PromotionType.percentage
      ? '${promotion.percentage ?? 0}%'
      : '${_money(promotion.salePrice ?? 0)} VND';

  String _duration(Promotion promotion) {
    if (!promotion.isLimitedTime ||
        promotion.startAt == null ||
        promotion.endAt == null) {
      return 'Unlimited';
    }
    return '${_date(promotion.startAt!)} - ${_date(promotion.endAt!)}';
  }

  String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _money(double value) => value
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match.group(1)},',
      );
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.label, this.value, this.color, this.icon);

  final String label;
  final int value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text('$value', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ],
      ),
    ),
  );
}

class _PromotionCard extends StatelessWidget {
  const _PromotionCard({
    required this.promotion,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleDisabled,
  });

  final Promotion promotion;
  final VoidCallback? onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleDisabled;

  String _money(double value) => value
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match.group(1)},',
      );

  String _duration(Promotion promotion) {
    if (!promotion.isLimitedTime ||
        promotion.startAt == null ||
        promotion.endAt == null) {
      return 'Unlimited';
    }
    String date(DateTime value) =>
        '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
    return '${date(promotion.startAt!)} - ${date(promotion.endAt!)}';
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  promotion.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _StatusBadge(status: promotion.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            promotion.type == PromotionType.percentage
                ? 'Discount: ${promotion.percentage ?? 0}%'
                : 'Sale price: ${_money(promotion.salePrice ?? 0)} VND',
          ),
          if (promotion.type == PromotionType.fixedAmount &&
              promotion.thresholdPrice != null)
            Text('Threshold: ${_money(promotion.thresholdPrice!)} VND'),
          Text(
            'Stock: ${promotion.isReservedStock ? promotion.maxReservedStock ?? 0 : 'Unlimited'}',
          ),
          Text('Duration: ${_duration(promotion)}'),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: promotion.isDeleted ? null : onToggleDisabled,
                icon: Icon(
                  promotion.isDisabled
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                tooltip: promotion.isDisabled ? 'Enable' : 'Disable',
              ),
              IconButton(
                onPressed: promotion.isDeleted ? null : onEdit,
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit',
              ),
              IconButton(
                onPressed: promotion.isDeleted ? null : onDelete,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Delete',
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'Active' => Colors.green,
      'Upcoming' => Colors.orange,
      'Disabled' || 'Deleted' => Colors.grey,
      _ => Colors.red,
    };
    return Chip(
      label: Text(status),
      backgroundColor: color.withValues(alpha: .15),
      labelStyle: TextStyle(color: color),
    );
  }
}

class PromotionEditorDialog extends StatefulWidget {
  const PromotionEditorDialog({super.key, required this.api, this.promotion});

  final PromotionApi api;
  final Promotion? promotion;

  @override
  State<PromotionEditorDialog> createState() => _PromotionEditorDialogState();
}

class _PromotionEditorDialogState extends State<PromotionEditorDialog> {
  late final TextEditingController _name;
  late final TextEditingController _value;
  late final TextEditingController _threshold;
  late final TextEditingController _stock;
  late PromotionType _type;
  late bool _reserved;
  late bool _limited;
  late bool _disabled;
  DateTime? _startAt;
  DateTime? _endAt;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = widget.promotion;
    _name = TextEditingController(text: p?.name);
    _type = p?.type ?? PromotionType.percentage;
    _value = TextEditingController(
      text: p == null
          ? ''
          : (p.type == PromotionType.percentage
                ? '${p.percentage ?? ''}'
                : p.salePrice?.toStringAsFixed(0) ?? ''),
    );
    _threshold = TextEditingController(
      text: p?.thresholdPrice?.toStringAsFixed(0) ?? '',
    );
    _stock = TextEditingController(text: p?.maxReservedStock?.toString() ?? '');
    _reserved = p?.isReservedStock ?? true;
    _limited = p?.isLimitedTime ?? false;
    _disabled = p?.isDisabled ?? false;
    _startAt = p?.startAt;
    _endAt = p?.endAt;
  }

  @override
  void dispose() {
    _name.dispose();
    _value.dispose();
    _threshold.dispose();
    _stock.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    double? parseVnd(String text) =>
        double.tryParse(text.replaceAll(RegExp(r'[.,\s]'), ''));

    double? parsePercent(String text) =>
        double.tryParse(text.trim().replaceAll(',', '.'));

    final value = _type == PromotionType.fixedAmount
        ? parseVnd(_value.text)
        : parsePercent(_value.text);
    final threshold = parseVnd(_threshold.text);
    final stock = int.tryParse(_stock.text.trim().replaceAll(',', ''));
    final name = _name.text.trim();
    final invalidFixedAmount =
        _type == PromotionType.fixedAmount &&
        (threshold == null ||
            threshold <= 0 ||
            value == null ||
            value >= threshold);
    if (_name.text.trim().isEmpty ||
        value == null ||
        value <= 0 ||
        (_type == PromotionType.percentage && value > 100) ||
        invalidFixedAmount ||
        (_reserved && (stock == null || stock <= 0)) ||
        (_limited &&
            (_startAt == null ||
                _endAt == null ||
                !_endAt!.isAfter(_startAt!)))) {
      setState(
        () => _error =
            'Check name, value (> 0), stock (> 0), threshold, and dates.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final input = PromotionInput(
      name: name,
      type: _type,
      salePrice: _type == PromotionType.fixedAmount ? value : null,
      thresholdPrice: _type == PromotionType.fixedAmount ? threshold : null,
      percentage: _type == PromotionType.percentage ? value : null,
      isReservedStock: _reserved,
      maxReservedStock: _reserved ? stock : null,
      isLimitedTime: _limited,
      startAt: _limited ? _startAt : null,
      endAt: _limited ? _endAt : null,
      isDisable: _disabled,
    );
    try {
      if (widget.promotion == null) {
        await widget.api.create(input);
      } else {
        await widget.api.update(widget.promotion!.id, input);
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error.toString();
        });
      }
    }
  }

  Future<void> _pickDate(bool start) async {
    final initial = (start ? _startAt : _endAt) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    final previous = start ? _startAt : _endAt;
    final date = DateTime(
      picked.year,
      picked.month,
      picked.day,
      previous?.hour ?? (start ? 0 : 23),
      previous?.minute ?? (start ? 0 : 59),
      previous?.second ?? 0,
      previous?.millisecond ?? 0,
      previous?.microsecond ?? 0,
    );
    setState(() {
      if (start) {
        _startAt = date;
      } else {
        _endAt = date;
      }
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.promotion == null ? 'Add promotion' : 'Update promotion',
    ),
    content: SizedBox(
      width: 560,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name *'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PromotionType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Promotion type'),
              items: const [
                DropdownMenuItem(
                  value: PromotionType.percentage,
                  child: Text('Percentage'),
                ),
                DropdownMenuItem(
                  value: PromotionType.fixedAmount,
                  child: Text('Fixed amount'),
                ),
              ],
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value == null || value == _type) return;
                      setState(() {
                        _type = value;
                        _value.clear();
                      });
                    },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _value,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: _type == PromotionType.percentage
                    ? 'Percentage (0-100) *'
                    : 'Sale price (VND) *',
              ),
              inputFormatters: _type == PromotionType.fixedAmount
                  ? [FilteringTextInputFormatter.digitsOnly]
                  : null,
            ),
            if (_type == PromotionType.fixedAmount) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _threshold,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Threshold price (VND) *',
                ),
              ),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Reserved stock'),
              value: _reserved,
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _reserved = value),
            ),
            if (_reserved)
              TextField(
                controller: _stock,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Maximum reserved stock *',
                ),
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Limited time'),
              value: _limited,
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _limited = value),
            ),
            if (_limited)
              Row(
                children: [
                  Expanded(
                    child: _dateButton(
                      'Start',
                      _startAt,
                      () => _pickDate(true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _dateButton('End', _endAt, () => _pickDate(false)),
                  ),
                ],
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Disable promotion'),
              value: _disabled,
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _disabled = value),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: _saving
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Save'),
      ),
    ],
  );

  Widget _dateButton(String label, DateTime? value, VoidCallback onPressed) =>
      OutlinedButton(
        onPressed: _saving ? null : onPressed,
        child: Text(
          value == null
              ? label
              : '$label: ${value.day}/${value.month}/${value.year}',
        ),
      );
}
