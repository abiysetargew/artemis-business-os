import 'package:artemis_business_os/core/network/api_errors.dart';
import 'package:artemis_business_os/core/providers.dart';
import 'package:artemis_business_os/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class InventoryItemDetailScreen extends ConsumerStatefulWidget {
  final String inventoryItemId;

  const InventoryItemDetailScreen({super.key, required this.inventoryItemId});

  @override
  ConsumerState<InventoryItemDetailScreen> createState() =>
      _InventoryItemDetailScreenState();
}

class _InventoryItemDetailScreenState
    extends ConsumerState<InventoryItemDetailScreen> {
  Map<String, dynamic>? _item;
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final results = await Future.wait<dynamic>([
        api.get('/inventory/${widget.inventoryItemId}'),
        api.get('/inventory/${widget.inventoryItemId}/transactions'),
      ]);
      setState(() {
        _item = results[0].data as Map<String, dynamic>;
        _transactions = results[1].data as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load inventory item';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Item'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: _item == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _showAdjustDialog,
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Adjust Stock'),
            ),
      body: _buildBody(),
    );
  }

  Future<void> _showAdjustDialog() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AdjustStockSheet(
        productName: _item?['productName'] as String? ?? '',
        currentQuantity: ((_item?['currentQuantity'] as num?) ?? 0).toDouble(),
        unitOfMeasure: _item?['unitOfMeasure'] as String? ?? 'piece',
        inventoryItemId: widget.inventoryItemId,
      ),
    );
    if (result == true) {
      _load();
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: List.generate(
          6,
          (index) => Card(
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(height: 60, color: Colors.white),
            ),
          ),
        ),
      );
    }
    if (_error != null || _item == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(_error ?? 'Item not found'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final item = _item!;
    final isLowStock = item['isLowStock'] == true;
    final currency = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 2);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: isLowStock
                ? Colors.red.shade50
                : AppTheme.primaryColor.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['productName'] as String? ?? 'Unknown',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      if (isLowStock)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'LOW STOCK',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SKU: ${item['productSku']}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricTile(
                          label: 'On hand',
                          value:
                              '${(item['currentQuantity'] as num).toStringAsFixed(2)} ${item['unitOfMeasure']}',
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Expanded(
                        child: _MetricTile(
                          label: 'Reorder at',
                          value:
                              '${(item['reorderPoint'] as num).toStringAsFixed(0)} ${item['unitOfMeasure']}',
                          color: AppTheme.warningColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricTile(
                          label: 'Avg cost',
                          value: currency.format(item['averageCost']),
                          color: Colors.indigo,
                        ),
                      ),
                      Expanded(
                        child: _MetricTile(
                          label: 'Total value',
                          value: currency.format(item['inventoryValue']),
                          color: AppTheme.successColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                'Transaction History',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                '${_transactions.length} entries',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_transactions.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.history,
                        size: 60,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 8),
                      const Text('No transactions yet'),
                    ],
                  ),
                ),
              ),
            )
          else
            ..._transactions.map<Widget>(_buildTransactionCard),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(dynamic t) {
    final type = t['transactionType'] as String;
    final isIn = type == 'GOODS_RECEIPT' || type == 'ADJUSTMENT_IN';
    final color = isIn ? AppTheme.successColor : AppTheme.warningColor;
    final icon = isIn ? Icons.arrow_downward : Icons.arrow_upward;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color, size: 18),
        ),
        title: Text(_labelForType(type)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('MMM dd, yyyy • HH:mm').format(
                DateTime.parse(t['transactionDate'] as String).toLocal(),
              ),
              style: const TextStyle(fontSize: 11),
            ),
            if (t['notes'] != null && (t['notes'] as String).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  t['notes'] as String,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isIn ? '+' : '-'}${(t['quantity'] as num).toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
            if (t['unitCostAtTransaction'] != null)
              Text(
                '@ ETB ${(t['unitCostAtTransaction'] as num).toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  String _labelForType(String type) {
    switch (type) {
      case 'GOODS_RECEIPT':
        return 'Goods Received';
      case 'GOODS_ISSUE':
        return 'Goods Issued';
      case 'PRODUCTION_CONSUMPTION':
        return 'Production Consumption';
      case 'SALES_OUT':
        return 'Sales Out';
      case 'ADJUSTMENT_IN':
        return 'Adjustment (In)';
      case 'ADJUSTMENT_OUT':
        return 'Adjustment (Out)';
      default:
        return type;
    }
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdjustStockSheet extends ConsumerStatefulWidget {
  final String productName;
  final double currentQuantity;
  final String unitOfMeasure;
  final String inventoryItemId;

  const _AdjustStockSheet({
    required this.productName,
    required this.currentQuantity,
    required this.unitOfMeasure,
    required this.inventoryItemId,
  });

  @override
  ConsumerState<_AdjustStockSheet> createState() => _AdjustStockSheetState();
}

class _AdjustStockSheetState extends ConsumerState<_AdjustStockSheet> {
  String _type = 'IN';
  final _qtyController = TextEditingController();
  final _unitCostController = TextEditingController();
  final _notesController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _qtyController.dispose();
    _unitCostController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final qty = double.tryParse(_qtyController.text);
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid quantity')),
      );
      return;
    }
    if (_type == 'OUT' && qty > widget.currentQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot remove ${qty.toStringAsFixed(0)} — only ${widget.currentQuantity.toStringAsFixed(0)} on hand',
          ),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final api = ref.read(apiClientProvider);
      final body = <String, dynamic>{
        'inventoryItemId': widget.inventoryItemId,
        'type': _type,
        'quantity': qty,
      };
      if (_unitCostController.text.isNotEmpty) {
        body['unitCost'] = double.tryParse(_unitCostController.text) ?? 0;
      }
      if (_notesController.text.isNotEmpty) {
        body['notes'] = _notesController.text;
      }
      await api.post('/inventory/adjustments', data: body);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(parseApiError(e)),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIn = _type == 'IN';
    final projected = isIn
        ? widget.currentQuantity + (double.tryParse(_qtyController.text) ?? 0)
        : widget.currentQuantity - (double.tryParse(_qtyController.text) ?? 0);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.slate200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Adjust Stock',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.slate900,
                        ),
                      ),
                      Text(
                        widget.productName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.slate500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _TypeOption(
                    selected: _type == 'IN',
                    label: 'Stock In',
                    description: 'Receive / add',
                    icon: Icons.arrow_downward_rounded,
                    color: AppTheme.successColor,
                    onTap: () => setState(() => _type = 'IN'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TypeOption(
                    selected: _type == 'OUT',
                    label: 'Stock Out',
                    description: 'Issue / remove',
                    icon: Icons.arrow_upward_rounded,
                    color: AppTheme.dangerColor,
                    onTap: () => setState(() => _type = 'OUT'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _qtyController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      suffixText: widget.unitOfMeasure,
                      hintText: '0',
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _unitCostController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Cost',
                      prefixText: 'ETB ',
                      hintText: 'opt',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (projected < 0
                        ? AppTheme.dangerLight
                        : AppTheme.slate50)
                    .withValues(alpha: projected < 0 ? 1 : 0.6),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: projected < 0
                      ? AppTheme.dangerColor
                      : AppTheme.slate200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    projected < 0
                        ? Icons.warning_amber_rounded
                        : Icons.calculate_outlined,
                    color: projected < 0
                        ? AppTheme.dangerColor
                        : AppTheme.slate600,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'After this ${_type == 'IN' ? 'addition' : 'removal'}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.slate500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${projected.toStringAsFixed(2)} ${widget.unitOfMeasure}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: projected < 0
                                ? AppTheme.dangerColor
                                : AppTheme.slate900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g. Supplier, reason, PO ref...',
                prefixIcon: Icon(Icons.note_outlined),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isIn
                      ? AppTheme.successColor
                      : AppTheme.dangerColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(isIn
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded),
                label: Text(
                  isIn ? 'Add Stock' : 'Remove Stock',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
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

class _TypeOption extends StatelessWidget {
  final bool selected;
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TypeOption({
    required this.selected,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : AppTheme.slate50,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: selected ? color : AppTheme.slate200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : AppTheme.slate500, size: 18),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: selected ? color : AppTheme.slate900,
              ),
            ),
            Text(
              description,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.slate500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
