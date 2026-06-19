import 'package:artemis_business_os/core/network/api_errors.dart';
import 'package:artemis_business_os/core/providers.dart';
import 'package:artemis_business_os/core/theme/app_theme.dart';
import 'package:artemis_business_os/core/widgets/confirm_dialog.dart';
import 'package:artemis_business_os/features/auth/application/auth_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class ProductionBatchesScreen extends ConsumerStatefulWidget {
  const ProductionBatchesScreen({super.key});

  @override
  ConsumerState<ProductionBatchesScreen> createState() =>
      _ProductionBatchesScreenState();
}

class _ProductionBatchesScreenState
    extends ConsumerState<ProductionBatchesScreen> {
  List<dynamic> _batches = [];
  List<dynamic> _products = [];
  String? _selectedProductId;
  DateTimeRange? _dateRange;
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

      final queryParams = <String, dynamic>{};
      if (_selectedProductId != null) {
        queryParams['finishedProductId'] = _selectedProductId;
      }
      if (_dateRange != null) {
        queryParams['dateFrom'] = _dateRange!.start.toIso8601String();
        queryParams['dateTo'] = _dateRange!.end.toIso8601String();
      }

      final results = await Future.wait<dynamic>([
        api.get('/production/batches', queryParameters: queryParams),
        api.get('/products', queryParameters: {'type': 'FINISHED_GOOD'}),
      ]);

      setState(() {
        _batches = results[0].data as List<dynamic>;
        _products = results[1].data as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load production batches';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Production Batches'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/production/create');
          _load();
        },
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Batch'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: _selectedProductId,
                    decoration: const InputDecoration(
                      labelText: 'Product',
                      prefixIcon: Icon(Icons.local_drink),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: <DropdownMenuItem<String?>>[
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All products'),
                      ),
                      ..._products.map<DropdownMenuItem<String?>>((p) {
                        return DropdownMenuItem<String?>(
                          value: p['id'] as String,
                          child: Text(
                            p['name'] as String,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                    ],
                    onChanged: (v) {
                      setState(() => _selectedProductId = v);
                      _load();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.date_range),
                  tooltip: 'Pick date range',
                ),
              ],
            ),
          ),
          if (_dateRange != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Chip(
                    label: Text(
                      '${DateFormat('MMM dd').format(_dateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_dateRange!.end)}',
                    ),
                    onDeleted: () {
                      setState(() => _dateRange = null);
                      _load();
                    },
                  ),
                ],
              ),
            ),
          if (!_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              width: double.infinity,
              child: Text(
                '${_batches.length} batch${_batches.length == 1 ? '' : 'es'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: 6,
        itemBuilder: (_, _) => Card(
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: ListTile(
              leading: const CircleAvatar(child: SizedBox()),
              title: Container(height: 14, color: Colors.white),
              subtitle: Container(height: 12, color: Colors.white),
            ),
          ),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(_error!),
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
    if (_batches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.factory, size: 100, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No production batches',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('Tap + to record a production batch'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _batches.length,
        itemBuilder: (context, i) => _buildBatchCard(_batches[i]),
      ),
    );
  }

  Widget _buildBatchCard(Map<String, dynamic> b) {
    final materialsCount = (b['materialsConsumed'] as List?)?.length ?? 0;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showBatchDetails(b),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.orange.shade100,
                    child: const Icon(
                      Icons.factory,
                      color: Colors.orange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b['batchNumber'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          b['finishedProductName'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${(b['quantityProduced'] as num).toStringAsFixed(0)} bottles',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 12,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy').format(
                      DateTime.parse(b['productionDate'] as String).toLocal(),
                    ),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.science, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '$materialsCount material${materialsCount == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (b['yieldPercentage'] != null) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${(b['yieldPercentage'] as num).toStringAsFixed(0)}% yield',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.successColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (materialsCount > 0) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: ((b['materialsConsumed'] as List?) ?? [])
                      .take(3)
                      .map<Widget>(
                        (m) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${m['materialName']}: ${(m['actualQuantity'] as num).toStringAsFixed(1)}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                if (ref.read(authNotifierProvider).user?.isAdmin ?? false)
                  Align(
                    alignment: Alignment.centerRight,
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (v) {
                        if (v == 'delete') {
                          _deleteBatch(b);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Delete batch',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteBatch(Map<String, dynamic> b) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Production Batch?',
      message:
          'Are you sure you want to delete batch ${b['batchNumber']}? This will reverse the inventory changes (add raw materials back, remove finished goods). This cannot be undone.',
      confirmLabel: 'Delete',
      type: ConfirmDialogType.highImpact,
    );
    if (!confirmed) return;
    try {
      final api = ref.read(apiClientProvider);
      await api.delete('/production/batches/${b['id']}');
      if (mounted) {
        showAppSnackBar(context, message: 'Batch deleted', isSuccess: true);
      }
      _load();
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, message: parseApiError(e), isError: true);
      }
    }
  }

  void _showBatchDetails(Map<String, dynamic> b) {
    final currency = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 2);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              b['batchNumber'] as String,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              b['finishedProductName'] as String,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _kv('Quantity produced', '${b['quantityProduced']} bottles'),
            _kv('BOM version', b['bomVersion']?.toString() ?? '—'),
            _kv('Production date', _fmtDate(b['productionDate'])),
            _kv('Recorded by', b['userName']?.toString() ?? '—'),
            if (b['yieldPercentage'] != null)
              _kv('Yield', '${b['yieldPercentage']}%'),
            if (b['notes'] != null && (b['notes'] as String).isNotEmpty)
              _kv('Notes', b['notes'] as String),
            const SizedBox(height: 16),
            const Text(
              'Materials consumed',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...((b['materialsConsumed'] as List?) ?? []).map<Widget>(
              (m) => Card(
                child: ListTile(
                  leading: const Icon(Icons.science, color: Colors.orange),
                  title: Text(m['materialName'] as String),
                  subtitle: Text(
                    'BOM: ${m['bomQuantity']} • Used: ${m['actualQuantity']}',
                  ),
                  trailing: Text(
                    currency.format(m['totalCost']),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            k,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            v,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );

  String _fmtDate(dynamic raw) {
    if (raw == null) return '—';
    try {
      return DateFormat(
        'MMM dd, yyyy • HH:mm',
      ).format(DateTime.parse(raw as String).toLocal());
    } catch (_) {
      return raw.toString();
    }
  }
}
