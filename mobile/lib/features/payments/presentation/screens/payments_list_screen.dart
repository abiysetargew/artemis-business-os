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

class PaymentsListScreen extends ConsumerStatefulWidget {
  const PaymentsListScreen({super.key});

  @override
  ConsumerState<PaymentsListScreen> createState() => _PaymentsListScreenState();
}

class _PaymentsListScreenState extends ConsumerState<PaymentsListScreen> {
  List<dynamic> _allPayments = [];
  List<dynamic> _filteredPayments = [];
  bool _isLoading = true;
  String _statusFilter = 'ALL'; // ALL, PENDING, VERIFIED, REJECTED
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('/payments');
      setState(() {
        _allPayments = res.data as List<dynamic>;
        _isLoading = false;
        _applyFilters();
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    var filtered = List<dynamic>.from(_allPayments);

    if (_statusFilter != 'ALL') {
      filtered = filtered
          .where((p) => p['verificationStatus'] == _statusFilter)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((p) {
        return (p['customerName'] as String).toLowerCase().contains(q) ||
            (p['referenceNumber'] as String? ?? '').toLowerCase().contains(q);
      }).toList();
    }

    setState(() => _filteredPayments = filtered);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPayments),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/payments/create'),
        icon: const Icon(Icons.add),
        label: const Text('New Payment'),
        backgroundColor: AppTheme.successColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by customer or reference...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _searchQuery = '');
                          _applyFilters();
                        },
                      )
                    : null,
              ),
              onChanged: (v) {
                setState(() => _searchQuery = v);
                _applyFilters();
              },
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'All',
                  value: 'ALL',
                  current: _statusFilter,
                  onTap: (v) {
                    setState(() => _statusFilter = v);
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Pending',
                  value: 'PENDING',
                  current: _statusFilter,
                  onTap: (v) {
                    setState(() => _statusFilter = v);
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Verified',
                  value: 'VERIFIED',
                  current: _statusFilter,
                  onTap: (v) {
                    setState(() => _statusFilter = v);
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Rejected',
                  value: 'REJECTED',
                  current: _statusFilter,
                  onTap: (v) {
                    setState(() => _statusFilter = v);
                    _applyFilters();
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
                '${_filteredPayments.length} payment${_filteredPayments.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Expanded(
            child: _isLoading
                ? _buildShimmer()
                : _filteredPayments.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
                    onRefresh: _loadPayments,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _filteredPayments.length,
                      itemBuilder: (context, index) =>
                          _buildPaymentCard(_filteredPayments[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: ListTile(
              leading: const CircleAvatar(child: SizedBox()),
              title: Container(height: 16, color: Colors.white),
              subtitle: Container(height: 12, color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payments_outlined, size: 100, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No payments found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text('Tap + to record a payment'),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final status = payment['verificationStatus'] as String;
    final color = status == 'VERIFIED'
        ? Colors.green
        : (status == 'REJECTED' ? Colors.red : Colors.orange);
    return Card(
      child: InkWell(
        onTap: () {
          context.push('/payments/${payment['id']}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.1),
                child: Icon(Icons.payments, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment['customerName'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${DateFormat('MMM dd, yyyy').format(DateTime.parse(payment['paymentDate'] as String))} • ${payment['paymentMethod']}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    if (payment['referenceNumber'] != null)
                      Text(
                        'Ref: ${payment['referenceNumber']}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'ETB ${(payment['amount'] as num).toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 9,
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (ref.read(authNotifierProvider).user?.isAdmin ?? false)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (v) {
                    if (v == 'delete') {
                      _deletePayment(payment);
                    }
                  },
                  itemBuilder: (_) => [
                    if (status != 'VERIFIED')
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    if (status == 'VERIFIED')
                      const PopupMenuItem(
                        enabled: false,
                        child: Row(
                          children: [
                            Icon(Icons.lock, size: 18, color: Colors.grey),
                            SizedBox(width: 8),
                            Text(
                              'Verified (cannot delete)',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deletePayment(Map<String, dynamic> payment) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Payment?',
      message:
          'Are you sure you want to delete payment of ETB ${(payment['amount'] as num).toStringAsFixed(2)}? This cannot be undone.',
      confirmLabel: 'Delete',
      type: ConfirmDialogType.destructive,
    );
    if (!confirmed) return;
    try {
      final api = ref.read(apiClientProvider);
      await api.delete('/payments/${payment['id']}');
      if (mounted) {
        showAppSnackBar(context, message: 'Payment deleted', isSuccess: true);
      }
      _loadPayments();
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, message: parseApiError(e), isError: true);
      }
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final Function(String) onTap;
  const _FilterChip({
    required this.label,
    required this.value,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = current == value;
    return FilterChip(
      label: Text(label),
      selected: isActive,
      onSelected: (_) => onTap(value),
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.primaryColor,
    );
  }
}
