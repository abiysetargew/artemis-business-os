import 'package:artemis_business_os/core/providers.dart';
import 'package:artemis_business_os/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  Map<String, dynamic>? _dashboard;
  Map<String, dynamic>? _aging;
  List<dynamic> _outstanding = [];
  List<dynamic> _lowStock = [];
  bool _isLoading = true;
  String? _error;
  ReportView _view = ReportView.overview;

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
        api.get('/reports/dashboard'),
        api.get('/receivables/aging'),
        api.get('/receivables/outstanding'),
        api.get('/inventory/low-stock'),
      ]);
      setState(() {
        _dashboard = results[0].data as Map<String, dynamic>;
        _aging = results[1].data as Map<String, dynamic>;
        _outstanding =
            (results[2].data as Map<String, dynamic>)['customers']
                as List<dynamic>? ??
            [];
        _lowStock = results[3].data as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load reports';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _viewChip(ReportView.overview, 'Overview', Icons.dashboard),
                const SizedBox(width: 8),
                _viewChip(
                  ReportView.receivables,
                  'Receivables',
                  Icons.account_balance_wallet,
                ),
                const SizedBox(width: 8),
                _viewChip(ReportView.aging, 'Aging', Icons.schedule),
                const SizedBox(width: 8),
                _viewChip(ReportView.inventory, 'Inventory', Icons.inventory_2),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _viewChip(ReportView v, String label, IconData icon) {
    final selected = _view == v;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: selected ? Colors.white : null),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: selected,
      selectedColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: selected ? Colors.white : null,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => setState(() => _view = v),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: List.generate(
          4,
          (i) => Card(
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(height: 80, color: Colors.white),
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

    switch (_view) {
      case ReportView.overview:
        return _buildOverview();
      case ReportView.receivables:
        return _buildReceivables();
      case ReportView.aging:
        return _buildAging();
      case ReportView.inventory:
        return _buildInventory();
    }
  }

  Widget _buildOverview() {
    final d = _dashboard!;
    final currency = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Today', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  title: 'Daily Sales',
                  value: currency.format(d['dailySales'] ?? 0),
                  icon: Icons.trending_up,
                  color: AppTheme.successColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _KpiCard(
                  title: 'Monthly Sales',
                  value: currency.format(d['monthlySales'] ?? 0),
                  icon: Icons.calendar_month,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  title: 'Receivables',
                  value: currency.format(d['totalOutstandingReceivables'] ?? 0),
                  icon: Icons.account_balance_wallet,
                  color: AppTheme.warningColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _KpiCard(
                  title: 'Inventory Value',
                  value: currency.format(d['totalInventoryValue'] ?? 0),
                  icon: Icons.inventory_2,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if ((d['topProducts'] as List?)?.isNotEmpty ?? false) ...[
            Text(
              'Top Products (30 days)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: ((d['topProducts'] as List?) ?? [])
                    .take(5)
                    .map<Widget>((p) {
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.orange,
                          child: Icon(
                            Icons.local_drink,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        title: Text(p['productName'] as String),
                        subtitle: Text('${p['totalQuantity']} units sold'),
                        trailing: Text(
                          currency.format(p['totalRevenue']),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    })
                    .toList(),
              ),
            ),
          ],
          if ((d['topCustomers'] as List?)?.isNotEmpty ?? false) ...[
            const SizedBox(height: 16),
            Text(
              'Top Customers (30 days)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: ((d['topCustomers'] as List?) ?? [])
                    .take(5)
                    .map<Widget>((c) {
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.purple,
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        title: Text(c['customerName'] as String),
                        subtitle: Text(
                          'Owes: ${currency.format(c['outstandingBalance'])}',
                        ),
                        trailing: Text(
                          currency.format(c['totalPurchases']),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    })
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReceivables() {
    final currency = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);
    final total = _outstanding.fold<double>(
      0,
      (sum, c) => sum + ((c['outstandingBalance'] as num?)?.toDouble() ?? 0),
    );
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: AppTheme.warningColor.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('Total Outstanding'),
                  const SizedBox(height: 4),
                  Text(
                    currency.format(total),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.warningColor,
                    ),
                  ),
                  Text('${_outstanding.length} customers'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_outstanding.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No outstanding balances')),
            )
          else
            ..._outstanding.map<Widget>((c) {
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: ((c['outstandingBalance'] as num) > 0)
                        ? Colors.red.shade100
                        : Colors.green.shade100,
                    child: Icon(
                      Icons.business,
                      color: ((c['outstandingBalance'] as num) > 0)
                          ? Colors.red
                          : Colors.green,
                      size: 20,
                    ),
                  ),
                  title: Text(c['customerName'] as String),
                  subtitle: Text(
                    'Credit limit: ${currency.format(c['creditLimit'])} • Available: ${currency.format(c['availableCredit'])}',
                  ),
                  trailing: Text(
                    currency.format(c['outstandingBalance']),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildAging() {
    final currency = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);
    final a = _aging ?? {};
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Aging Buckets', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _AgingTile(
            label: 'Current (0-30 days)',
            amount: (a['current'] as num?)?.toDouble() ?? 0,
            color: AppTheme.successColor,
            currency: currency,
          ),
          _AgingTile(
            label: '31-60 days',
            amount: (a['days31to60'] as num?)?.toDouble() ?? 0,
            color: Colors.amber,
            currency: currency,
          ),
          _AgingTile(
            label: '61-90 days',
            amount: (a['days61to90'] as num?)?.toDouble() ?? 0,
            color: Colors.orange,
            currency: currency,
          ),
          _AgingTile(
            label: 'Over 90 days',
            amount: (a['over90'] as num?)?.toDouble() ?? 0,
            color: Colors.red,
            currency: currency,
          ),
          if ((a['details'] as List?) != null) ...[
            const SizedBox(height: 16),
            const Text(
              'Top overdue',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...((a['details'] as List?) ?? []).take(10).map<Widget>((d) {
              return Card(
                child: ListTile(
                  title: Text(d['customerName']?.toString() ?? '—'),
                  subtitle: Text(
                    'Oldest: ${d['oldestInvoiceDays'] ?? '—'} days',
                  ),
                  trailing: Text(
                    currency.format(d['amount']),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildInventory() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Low Stock Items',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (_lowStock.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 60,
                        color: AppTheme.successColor,
                      ),
                      const SizedBox(height: 8),
                      const Text('No low-stock items'),
                    ],
                  ),
                ),
              ),
            )
          else
            ..._lowStock.map<Widget>((item) {
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.red,
                    child: Icon(Icons.warning, color: Colors.white, size: 18),
                  ),
                  title: Text(item['productName'] as String),
                  subtitle: Text(
                    'SKU: ${item['sku']} • Reorder at: ${item['reorderPoint']} ${item['unitOfMeasure']}',
                  ),
                  trailing: Text(
                    '${(item['currentQuantity'] as num).toStringAsFixed(1)} ${item['unitOfMeasure']}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

enum ReportView { overview, receivables, aging, inventory }

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _AgingTile extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final NumberFormat currency;

  const _AgingTile({
    required this.label,
    required this.amount,
    required this.color,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Text(
              currency.format(amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
