import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:artemis_business_os/core/providers.dart';
import 'package:artemis_business_os/core/theme/app_theme.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  ConsumerState<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  Map<String, dynamic>? _customer;
  List<dynamic> _ledger = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCustomer();
  }

  Future<void> _loadCustomer() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final customerRes = await api.get('/customers/${widget.customerId}');
      final ledgerRes = await api.get('/customers/${widget.customerId}/ledger');
      setState(() {
        _customer = customerRes.data as Map<String, dynamic>;
        _ledger = ledgerRes.data as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load customer details';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _customer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(_error ?? 'Customer not found'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadCustomer,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final c = _customer!;
    final balance = c['outstandingBalance'] as num;
    final creditLimit = c['creditLimit'] as num;
    final availableCredit = creditLimit - balance;
    final hasBalance = balance > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(c['name'] as String),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadCustomer),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCustomer,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Customer Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: hasBalance
                              ? Colors.red.shade100
                              : Colors.green.shade100,
                          child: Text(
                            (c['name'] as String).substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              fontSize: 24,
                              color: hasBalance ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c['name'] as String,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                c['phoneNumber'] as String,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: c['accountStatus'] == 'ACTIVE'
                                ? Colors.green.shade100
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            c['accountStatus'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              color: c['accountStatus'] == 'ACTIVE'
                                  ? Colors.green
                                  : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      Icons.person,
                      'Contact',
                      c['contactPerson'] as String? ?? 'N/A',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.location_on,
                      'Region/City',
                      '${c['region']} / ${c['city']}',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.home,
                      'Address',
                      c['address'] as String? ?? 'N/A',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Financial Summary Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Financial Summary',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFinancialTile(
                            'Outstanding',
                            'ETB ${balance.toStringAsFixed(0)}',
                            hasBalance ? Colors.red : Colors.green,
                            hasBalance ? Icons.warning : Icons.check_circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildFinancialTile(
                            'Credit Limit',
                            'ETB ${creditLimit.toStringAsFixed(0)}',
                            AppTheme.primaryColor,
                            Icons.account_balance,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFinancialTile(
                            'Available',
                            'ETB ${availableCredit.clamp(0, double.infinity).toStringAsFixed(0)}',
                            availableCredit > 0 ? Colors.green : Colors.red,
                            Icons.account_balance_wallet,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildFinancialTile(
                            'Transactions',
                            '${_ledger.length}',
                            Colors.blue,
                            Icons.receipt_long,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/sales/create'),
                    icon: const Icon(Icons.point_of_sale),
                    label: const Text('New Sale'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/payments/create'),
                    icon: const Icon(Icons.payment),
                    label: const Text('Collect'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Transaction Ledger
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaction History',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${_ledger.length} entries',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ledger.isEmpty
                ? Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 60,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No transactions yet',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  )
                : Card(child: Column(children: _buildLedgerEntries())),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLedgerEntries() {
    final currencyFormat = NumberFormat.currency(
      symbol: 'ETB ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('MMM dd, yyyy');
    double runningBalance = 0;

    return _ledger.asMap().entries.map<Widget>((entry) {
      final i = entry.key;
      final item = entry.value as Map<String, dynamic>;
      final isSale = item['type'] == 'SALE';
      final debit = (item['debit'] as num).toDouble();
      final credit = (item['credit'] as num).toDouble();
      runningBalance += debit - credit;

      return Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: (isSale ? Colors.orange : Colors.green)
                  .withValues(alpha: 0.1),
              child: Icon(
                isSale ? Icons.shopping_cart : Icons.payments,
                color: isSale ? Colors.orange : Colors.green,
                size: 20,
              ),
            ),
            title: Text(
              item['description'] as String,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            subtitle: Text(
              '${dateFormat.format(DateTime.parse(item['date'] as String))} • ${item['reference']}',
              style: const TextStyle(fontSize: 11),
            ),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (debit > 0)
                  Text(
                    '+${currencyFormat.format(debit)}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                if (credit > 0)
                  Text(
                    '-${currencyFormat.format(credit)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                Text(
                  'Bal: ${currencyFormat.format(runningBalance)}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (i < _ledger.length - 1) const Divider(height: 1),
        ],
      );
    }).toList();
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ],
    );
  }

  Widget _buildFinancialTile(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
