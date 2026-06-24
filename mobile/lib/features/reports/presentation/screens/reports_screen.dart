import 'package:artemis_business_os/core/providers.dart';
import 'package:artemis_business_os/core/theme/app_theme.dart';
import 'package:artemis_business_os/core/widgets/data_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

enum ReportTab { overview, sales, payments, inventory, production, receivables }

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportTab _tab = ReportTab.overview;
  DateTimeRange? _dateRange;
  Map<String, dynamic>? _data;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _dateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 29)),
      end: DateTime.now(),
    );
    _load();
  }

  String get _dateParams {
    if (_dateRange == null) return '';
    final df = DateFormat('yyyy-MM-dd').format(_dateRange!.start);
    final dt = DateFormat('yyyy-MM-dd').format(_dateRange!.end);
    return 'dateFrom=$df&dateTo=$dt';
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      String endpoint;
      switch (_tab) {
        case ReportTab.overview:
          endpoint = '/reports/dashboard';
          break;
        case ReportTab.sales:
          endpoint = '/reports/sales?$_dateParams';
          break;
        case ReportTab.payments:
          endpoint = '/reports/payments?$_dateParams';
          break;
        case ReportTab.inventory:
          endpoint = '/reports/inventory';
          break;
        case ReportTab.production:
          endpoint = '/reports/production?$_dateParams';
          break;
        case ReportTab.receivables:
          endpoint = '/receivables/outstanding';
          break;
      }
      final response = await api.get(endpoint);
      setState(() {
        _data = response.data as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load report';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 7)),
      initialDateRange: _dateRange,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppTheme.primaryColor,
            primary: AppTheme.primaryColor,
          ),
        ),
        child: child!,
      ),
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
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _pickDateRange,
            tooltip: 'Date range',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(),
          if (_dateRange != null &&
              _tab != ReportTab.inventory &&
              _tab != ReportTab.receivables)
            _buildDateRangeChip(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _buildError()
                : RefreshIndicator(onRefresh: _load, child: _buildTabContent()),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          for (final t in ReportTab.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(_labelFor(t)),
                selected: _tab == t,
                onSelected: (_) {
                  setState(() => _tab = t);
                  _load();
                },
                selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                checkmarkColor: AppTheme.primaryColor,
                labelStyle: TextStyle(
                  color: _tab == t ? AppTheme.primaryColor : AppTheme.slate700,
                  fontWeight: _tab == t ? FontWeight.w600 : FontWeight.w500,
                ),
                side: BorderSide(
                  color: _tab == t
                      ? AppTheme.primaryColor.withValues(alpha: 0.3)
                      : AppTheme.slate200,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateRangeChip() {
    final df = DateFormat('MMM dd').format(_dateRange!.start);
    final dt = DateFormat('MMM dd, yyyy').format(_dateRange!.end);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          ActionChip(
            avatar: const Icon(Icons.calendar_today, size: 16),
            label: Text('$df – $dt'),
            onPressed: _pickDateRange,
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _dateRange = null;
              });
              _load();
            },
            child: const Text('All time'),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppTheme.slate300),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: AppTheme.slate600)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    if (_data == null) {
      return const EmptyState(
        icon: Icons.analytics,
        title: 'No data',
        subtitle: 'Try a different date range',
      );
    }
    switch (_tab) {
      case ReportTab.overview:
        return _OverviewTab(data: _data!);
      case ReportTab.sales:
        return _SalesTab(data: _data!);
      case ReportTab.payments:
        return _PaymentsTab(data: _data!);
      case ReportTab.inventory:
        return _InventoryTab(data: _data!);
      case ReportTab.production:
        return _ProductionTab(data: _data!);
      case ReportTab.receivables:
        return _ReceivablesTab(data: _data!);
    }
  }

  String _labelFor(ReportTab t) {
    switch (t) {
      case ReportTab.overview:
        return 'Overview';
      case ReportTab.sales:
        return 'Sales';
      case ReportTab.payments:
        return 'Payments';
      case ReportTab.inventory:
        return 'Inventory';
      case ReportTab.production:
        return 'Production';
      case ReportTab.receivables:
        return 'Receivables';
    }
  }
}

// ============================================================================
// OVERVIEW TAB
// ============================================================================
class _OverviewTab extends StatelessWidget {
  final Map<String, dynamic> data;
  const _OverviewTab({required this.data});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);
    final dailySales = (data['dailySales'] as num?)?.toDouble() ?? 0;
    final monthlySales = (data['monthlySales'] as num?)?.toDouble() ?? 0;
    final receivables =
        (data['totalOutstandingReceivables'] as num?)?.toDouble() ?? 0;
    final inventoryValue =
        (data['totalInventoryValue'] as num?)?.toDouble() ?? 0;
    final topProducts = (data['topProducts'] as List?) ?? [];
    final topCustomers = (data['topCustomers'] as List?) ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                title: "Today's Sales",
                value: currency.format(dailySales),
                icon: Icons.trending_up,
                color: AppTheme.successColor,
                bgColor: AppTheme.successLight,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                title: 'This Month',
                value: currency.format(monthlySales),
                icon: Icons.calendar_month,
                color: AppTheme.primaryColor,
                bgColor: AppTheme.primaryLight,
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
                value: currency.format(receivables),
                icon: Icons.account_balance_wallet,
                color: AppTheme.warningColor,
                bgColor: AppTheme.warningLight,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                title: 'Inventory',
                value: currency.format(inventoryValue),
                icon: Icons.inventory_2,
                color: AppTheme.accentColor,
                bgColor: AppTheme.primaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (topProducts.isNotEmpty) ...[
          const _SectionLabel('Top Products'),
          const SizedBox(height: 8),
          _BarRankingCard(
            items: _take(
              topProducts,
              (p) => _RankItem(
                label: p['productName'] as String? ?? '',
                value: (p['totalRevenue'] as num?)?.toDouble() ?? 0,
                sub: '${p['totalQuantity']} units',
              ),
            ),
            valueFormat: currency.format,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 24),
        ],
        if (topCustomers.isNotEmpty) ...[
          const _SectionLabel('Top Customers'),
          const SizedBox(height: 8),
          _BarRankingCard(
            items: _take(
              topCustomers,
              (c) => _RankItem(
                label: c['customerName'] as String? ?? '',
                value: (c['totalPurchases'] as num?)?.toDouble() ?? 0,
                sub: 'Owes ${currency.format(c['outstandingBalance'])}',
              ),
            ),
            valueFormat: currency.format,
            color: AppTheme.accentColor,
          ),
        ],
      ],
    );
  }

  List<_RankItem> _take(List items, _RankItem Function(dynamic) mapper) {
    return items.take(5).map(mapper).toList();
  }
}

// ============================================================================
// SHARED ITEM CLASS
// ============================================================================
class _RankItem {
  final String label;
  final double value;
  final String sub;
  const _RankItem({
    required this.label,
    required this.value,
    required this.sub,
  });
}

// ============================================================================
// SALES TAB
// ============================================================================
class _SalesTab extends StatelessWidget {
  final Map<String, dynamic> data;
  const _SalesTab({required this.data});

  @override
  Widget build(BuildContext context) {
    final summary = data['summary'] as Map<String, dynamic>? ?? {};
    final daily = (data['daily'] as List?) ?? [];
    final bySalesRep = (data['bySalesRep'] as List?) ?? [];
    final topProducts = (data['topProducts'] as List?) ?? [];
    final topCustomers = (data['topCustomers'] as List?) ?? [];

    final currency = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);
    final totalRevenue = (summary['totalRevenue'] as num?)?.toDouble() ?? 0;
    final totalSales = summary['totalSales'] ?? 0;
    final paidRevenue = (summary['paidRevenue'] as num?)?.toDouble() ?? 0;
    final pendingRevenue = (summary['pendingRevenue'] as num?)?.toDouble() ?? 0;
    final cashRevenue = (summary['cashRevenue'] as num?)?.toDouble() ?? 0;
    final creditRevenue = (summary['creditRevenue'] as num?)?.toDouble() ?? 0;
    final avgOrder = (summary['averageOrderValue'] as num?)?.toDouble() ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatsRow(
          stats: [
            _StatItem(value: '${totalSales}', label: 'Total Orders'),
            _StatItem(
              value: currency.format(totalRevenue).replaceAll('ETB ', ''),
              label: 'Revenue',
            ),
            _StatItem(
              value: currency.format(avgOrder).replaceAll('ETB ', ''),
              label: 'Avg Order',
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (cashRevenue > 0 || creditRevenue > 0) ...[
          const _SectionLabel('Revenue Mix'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 140,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 32,
                          sections: [
                            PieChartSectionData(
                              value: cashRevenue,
                              title: '',
                              color: AppTheme.successColor,
                              radius: 32,
                            ),
                            PieChartSectionData(
                              value: creditRevenue,
                              title: '',
                              color: AppTheme.warningColor,
                              radius: 32,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LegendItem(
                          color: AppTheme.successColor,
                          label: 'Cash',
                          value: currency.format(cashRevenue),
                        ),
                        const SizedBox(height: 12),
                        _LegendItem(
                          color: AppTheme.warningColor,
                          label: 'Credit',
                          value: currency.format(creditRevenue),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Collection Rate',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.slate700,
                  ),
                ),
                const SizedBox(height: 12),
                _ProgressBar(
                  value: totalRevenue > 0 ? paidRevenue / totalRevenue : 0,
                  color: AppTheme.successColor,
                  label:
                      '${currency.format(paidRevenue)} of ${currency.format(totalRevenue)} collected',
                ),
                const SizedBox(height: 8),
                _ProgressBar(
                  value: totalRevenue > 0 ? pendingRevenue / totalRevenue : 0,
                  color: AppTheme.warningColor,
                  label: '${currency.format(pendingRevenue)} outstanding',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (daily.isNotEmpty) ...[
          const _SectionLabel('Daily Sales Trend'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 200,
                child: _DailyLineChart(
                  daily: daily.cast<Map<String, dynamic>>(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (topProducts.isNotEmpty) ...[
          const _SectionLabel('Top Products'),
          const SizedBox(height: 8),
          _BarRankingCard(
            items: topProducts
                .take(5)
                .map(
                  (p) => _RankItem(
                    label: p['name'] as String? ?? '',
                    value: (p['revenue'] as num?)?.toDouble() ?? 0,
                    sub: '${p['quantity']} units',
                  ),
                )
                .toList(),
            valueFormat: currency.format,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 24),
        ],
        if (topCustomers.isNotEmpty) ...[
          const _SectionLabel('Top Customers'),
          const SizedBox(height: 8),
          _BarRankingCard(
            items: topCustomers
                .take(5)
                .map(
                  (c) => _RankItem(
                    label: c['name'] as String? ?? '',
                    value: (c['revenue'] as num?)?.toDouble() ?? 0,
                    sub: '${c['count']} orders',
                  ),
                )
                .toList(),
            valueFormat: currency.format,
            color: AppTheme.accentColor,
          ),
          const SizedBox(height: 24),
        ],
        if (bySalesRep.isNotEmpty) ...[
          const _SectionLabel('Sales Rep Performance'),
          const SizedBox(height: 8),
          _BarRankingCard(
            items: bySalesRep
                .take(5)
                .map(
                  (r) => _RankItem(
                    label: r['name'] as String? ?? '',
                    value: (r['revenue'] as num?)?.toDouble() ?? 0,
                    sub: '${r['count']} orders',
                  ),
                )
                .toList(),
            valueFormat: currency.format,
            color: AppTheme.infoColor,
          ),
        ],
      ],
    );
  }
}

// ============================================================================
// PAYMENTS TAB
// ============================================================================
class _PaymentsTab extends StatelessWidget {
  final Map<String, dynamic> data;
  const _PaymentsTab({required this.data});

  @override
  Widget build(BuildContext context) {
    final summary = data['summary'] as Map<String, dynamic>? ?? {};
    final daily = (data['daily'] as List?) ?? [];
    final methods = (data['paymentMethods'] as List?) ?? [];

    final currency = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);
    final totalAmount = (summary['totalAmount'] as num?)?.toDouble() ?? 0;
    final verifiedAmount = (summary['verifiedAmount'] as num?)?.toDouble() ?? 0;
    final pendingAmount = (summary['pendingAmount'] as num?)?.toDouble() ?? 0;
    final totalPayments = summary['totalPayments'] ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatsRow(
          stats: [
            _StatItem(value: '${totalPayments}', label: 'Total'),
            _StatItem(
              value: currency.format(totalAmount).replaceAll('ETB ', ''),
              label: 'Collected',
            ),
            _StatItem(
              value: totalAmount > 0
                  ? '${((verifiedAmount / totalAmount) * 100).toStringAsFixed(0)}%'
                  : '0%',
              label: 'Verified',
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Verification Status',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.slate700,
                  ),
                ),
                const SizedBox(height: 12),
                _ProgressBar(
                  value: totalAmount > 0 ? verifiedAmount / totalAmount : 0,
                  color: AppTheme.successColor,
                  label: '${currency.format(verifiedAmount)} verified',
                ),
                const SizedBox(height: 8),
                _ProgressBar(
                  value: totalAmount > 0 ? pendingAmount / totalAmount : 0,
                  color: AppTheme.warningColor,
                  label: '${currency.format(pendingAmount)} pending',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (methods.isNotEmpty) ...[
          const _SectionLabel('By Payment Method'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (var i = 0; i < methods.take(5).length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _colorForIndex(i),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _humanizeMethod(
                                methods[i]['method'] as String? ?? '',
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${methods[i]['count']} txns',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.slate500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            currency.format(
                              (methods[i]['total'] as num?)?.toDouble() ?? 0,
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.slate900,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (daily.isNotEmpty) ...[
          const _SectionLabel('Daily Collections'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 200,
                child: _DailyLineChart(
                  daily: daily.cast<Map<String, dynamic>>(),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _humanizeMethod(String m) {
    return m
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  Color _colorForIndex(int i) {
    const colors = [
      AppTheme.primaryColor,
      AppTheme.successColor,
      AppTheme.warningColor,
      AppTheme.accentColor,
      AppTheme.infoColor,
    ];
    return colors[i % colors.length];
  }
}

// ============================================================================
// INVENTORY TAB
// ============================================================================
class _InventoryTab extends StatelessWidget {
  final Map<String, dynamic> data;
  const _InventoryTab({required this.data});

  @override
  Widget build(BuildContext context) {
    final summary = data['summary'] as Map<String, dynamic>? ?? {};
    final byCategory = (data['byCategory'] as List?) ?? [];
    final topValue = (data['topValue'] as List?) ?? [];
    final lowStock = (data['lowStockItems'] as List?) ?? [];

    final currency = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);
    final totalValue = (summary['totalValue'] as num?)?.toDouble() ?? 0;
    final totalItems = summary['totalItems'] ?? 0;
    final totalUnits = (summary['totalUnits'] as num?)?.toDouble() ?? 0;
    final lowStockCount = summary['lowStockCount'] ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatsRow(
          stats: [
            _StatItem(value: '${totalItems}', label: 'Products'),
            _StatItem(
              value: currency.format(totalValue).replaceAll('ETB ', ''),
              label: 'Total Value',
            ),
            _StatItem(
              value: '${totalUnits.toStringAsFixed(0)}',
              label: 'Total Units',
            ),
          ],
        ),
        if (lowStockCount > 0) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.dangerLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.dangerColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppTheme.dangerColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$lowStockCount item${lowStockCount == 1 ? '' : 's'} below reorder point',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.dangerColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (byCategory.isNotEmpty) ...[
          const _SectionLabel('Value by Category'),
          const SizedBox(height: 8),
          _BarRankingCard(
            items: byCategory
                .take(5)
                .map(
                  (c) => _RankItem(
                    label: c['category'] as String? ?? '',
                    value: (c['value'] as num?)?.toDouble() ?? 0,
                    sub:
                        '${c['items']} products • ${(c['units'] as num?)?.toStringAsFixed(0) ?? 0} units',
                  ),
                )
                .toList(),
            valueFormat: currency.format,
            color: AppTheme.accentColor,
          ),
          const SizedBox(height: 24),
        ],
        if (topValue.isNotEmpty) ...[
          const _SectionLabel('Highest Value Items'),
          const SizedBox(height: 8),
          _BarRankingCard(
            items: topValue
                .take(5)
                .map(
                  (p) => _RankItem(
                    label: p['name'] as String? ?? '',
                    value: (p['value'] as num?)?.toDouble() ?? 0,
                    sub:
                        '${(p['quantity'] as num?)?.toStringAsFixed(0) ?? 0} × ${currency.format((p['averageCost'] as num?)?.toDouble() ?? 0)}',
                  ),
                )
                .toList(),
            valueFormat: currency.format,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 24),
        ],
        if (lowStock.isNotEmpty) ...[
          const _SectionLabel('Low Stock Alerts'),
          const SizedBox(height: 8),
          for (final item in lowStock)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DataCard(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.dangerLight,
                  child: Icon(Icons.warning, color: AppTheme.dangerColor),
                ),
                title: item['name'] as String? ?? '',
                subtitle: item['sku'] as String? ?? '',
                badges: [
                  StatusBadge(
                    label: 'Qty: ${item['currentQuantity']}',
                    color: AppTheme.dangerColor,
                    icon: Icons.trending_down,
                  ),
                  StatusBadge(
                    label: 'Reorder at: ${item['reorderPoint']}',
                    color: AppTheme.slate500,
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

// ============================================================================
// PRODUCTION TAB
// ============================================================================
class _ProductionTab extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ProductionTab({required this.data});

  @override
  Widget build(BuildContext context) {
    final summary = data['summary'] as Map<String, dynamic>? ?? {};
    final daily = (data['daily'] as List?) ?? [];
    final byProduct = (data['byProduct'] as List?) ?? [];

    final totalBatches = summary['totalBatches'] ?? 0;
    final totalProduced = (summary['totalProduced'] as num?)?.toDouble() ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatsRow(
          stats: [
            _StatItem(value: '${totalBatches}', label: 'Batches'),
            _StatItem(
              value: '${totalProduced.toStringAsFixed(0)}',
              label: 'Units Produced',
            ),
            _StatItem(
              value: totalBatches > 0
                  ? '${(totalProduced / totalBatches).toStringAsFixed(0)}'
                  : '0',
              label: 'Avg per Batch',
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (daily.isNotEmpty) ...[
          const _SectionLabel('Daily Production'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 200,
                child: _DailyBarChart(
                  daily: daily.cast<Map<String, dynamic>>(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (byProduct.isNotEmpty) ...[
          const _SectionLabel('Production by Product'),
          const SizedBox(height: 8),
          _BarRankingCard(
            items: byProduct
                .take(5)
                .map(
                  (p) => _RankItem(
                    label: p['name'] as String? ?? '',
                    value: (p['quantity'] as num?)?.toDouble() ?? 0,
                    sub: '${p['batches']} batches',
                  ),
                )
                .toList(),
            valueFormat: (v) => v.toStringAsFixed(0),
            color: AppTheme.successColor,
          ),
        ],
      ],
    );
  }
}

// ============================================================================
// RECEIVABLES TAB
// ============================================================================
class _ReceivablesTab extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ReceivablesTab({required this.data});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);
    final customers = (data['customers'] as List?) ?? [];
    final total =
        (data['totalOutstanding'] as num?)?.toDouble() ??
        customers.fold<double>(
          0,
          (s, c) =>
              s +
              ((c as Map<String, dynamic>)['outstandingBalance'] as num? ?? 0)
                  .toDouble(),
        );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.warningColor, AppTheme.dangerColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              const Text(
                'Total Outstanding',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                currency.format(total),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${customers.length} customer${customers.length == 1 ? '' : 's'}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (customers.isEmpty)
          const EmptyState(
            icon: Icons.check_circle,
            title: 'All clear!',
            subtitle: 'No outstanding balances',
          )
        else
          for (final c in customers)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DataCard(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.warningLight,
                  child: Text(
                    (c['customerName'] as String? ?? '?')
                        .substring(0, 1)
                        .toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.warningColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                title: c['customerName'] as String? ?? '',
                subtitle: '${c['city']} • ${c['phoneNumber']}',
                badges: [
                  StatusBadge(
                    label: currency.format(
                      (c['outstandingBalance'] as num?)?.toDouble() ?? 0,
                    ),
                    color: AppTheme.dangerColor,
                  ),
                  StatusBadge(
                    label:
                        'Limit: ${currency.format((c['creditLimit'] as num?)?.toDouble() ?? 0)}',
                    color: AppTheme.slate500,
                  ),
                ],
                meta: [
                  MetaItem(
                    icon: Icons.account_balance_wallet,
                    label:
                        'Available: ${currency.format((c['availableCredit'] as num?)?.toDouble() ?? 0)}',
                  ),
                ],
                onTap: () => context.push('/customers/${c['id']}'),
                menuBuilder: () => [
                  const PopupMenuItem<String>(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility, size: 18),
                        SizedBox(width: 8),
                        Text('View details'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'pay',
                    child: Row(
                      children: [
                        Icon(Icons.payment, size: 18),
                        SizedBox(width: 8),
                        Text('Record payment'),
                      ],
                    ),
                  ),
                ],
                onMenuSelected: (v) {
                  if (v == 'pay') context.push('/payments/create');
                },
              ),
            ),
      ],
    );
  }
}

// ============================================================================
// SHARED WIDGETS
// ============================================================================
class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.slate500,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.slate900,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppTheme.slate700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _StatItem {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});
}

class _StatsRow extends StatelessWidget {
  final List<_StatItem> stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            for (var i = 0; i < stats.length; i++) ...[
              Expanded(
                child: Column(
                  children: [
                    Text(
                      stats[i].value,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.slate900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stats[i].label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.slate500,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (i < stats.length - 1)
                Container(height: 32, width: 1, color: AppTheme.slate200),
            ],
          ],
        ),
      ),
    );
  }
}

class _BarRankingCard extends StatelessWidget {
  final List<_RankItem> items;
  final String Function(double) valueFormat;
  final Color color;

  const _BarRankingCard({
    required this.items,
    required this.valueFormat,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final max = items.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++)
              Padding(
                padding: EdgeInsets.only(bottom: i < items.length - 1 ? 12 : 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            items[i].label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          valueFormat(items[i].value),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.slate900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: max > 0
                                  ? (items[i].value / max).clamp(0.0, 1.0)
                                  : 0,
                              minHeight: 8,
                              backgroundColor: AppTheme.slate100,
                              valueColor: AlwaysStoppedAnimation(color),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          items[i].sub,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.slate500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.slate500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.slate900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final String label;

  const _ProgressBar({
    required this.value,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: AppTheme.slate100,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.slate500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _DailyLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> daily;
  const _DailyLineChart({required this.daily});

  @override
  Widget build(BuildContext context) {
    if (daily.isEmpty) return const SizedBox.shrink();

    final spots = <FlSpot>[];
    for (var i = 0; i < daily.length; i++) {
      final value = (daily[i]['revenue'] as num?)?.toDouble() ?? 0;
      spots.add(FlSpot(i.toDouble(), value));
    }

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final niceMax = maxY * 1.2;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: niceMax == 0 ? 100 : niceMax,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: niceMax / 4,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppTheme.slate200, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: (daily.length / 5).clamp(1, 30).toDouble(),
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= daily.length)
                  return const SizedBox.shrink();
                final date = daily[idx]['date'] as String? ?? '';
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    date.length >= 10 ? date.substring(5, 10) : date,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.slate500,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              interval: niceMax / 4,
              getTitlesWidget: (value, _) {
                if (value == 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    '${(value / 1000).toStringAsFixed(0)}k',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.slate500,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppTheme.slate900,
            getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
              final idx = s.x.toInt();
              final date = daily[idx]['date'] as String? ?? '';
              return LineTooltipItem(
                '$date\n${NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0).format(s.y)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppTheme.primaryColor,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.25),
                  AppTheme.primaryColor.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> daily;
  const _DailyBarChart({required this.daily});

  @override
  Widget build(BuildContext context) {
    if (daily.isEmpty) return const SizedBox.shrink();

    final groups = <BarChartGroupData>[];
    double maxY = 0;
    for (var i = 0; i < daily.length; i++) {
      final value = (daily[i]['quantity'] as num?)?.toDouble() ?? 0;
      if (value > maxY) maxY = value;
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: value,
              color: AppTheme.successColor,
              width: 12,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.2 == 0 ? 100 : maxY * 1.2,
        barGroups: groups,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppTheme.slate200, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: (daily.length / 5).clamp(1, 30).toDouble(),
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= daily.length)
                  return const SizedBox.shrink();
                final date = daily[idx]['date'] as String? ?? '';
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    date.length >= 10 ? date.substring(5, 10) : date,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.slate500,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: maxY / 4,
              getTitlesWidget: (value, _) {
                if (value == 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    value.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.slate500,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppTheme.slate900,
            getTooltipItem: (group, _, rod, __) {
              final date = daily[group.x]['date'] as String? ?? '';
              return BarTooltipItem(
                '$date\n${rod.toY.toStringAsFixed(0)} units',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
