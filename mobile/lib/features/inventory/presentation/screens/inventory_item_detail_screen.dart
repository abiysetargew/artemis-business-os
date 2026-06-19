import 'package:artemis_business_os/core/providers.dart';
import 'package:artemis_business_os/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
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
      body: _buildBody(),
    );
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
