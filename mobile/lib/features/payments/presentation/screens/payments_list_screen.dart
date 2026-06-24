import 'package:artemis_business_os/core/network/api_errors.dart';
import 'package:artemis_business_os/core/providers.dart';
import 'package:artemis_business_os/core/theme/app_theme.dart';
import 'package:artemis_business_os/core/widgets/confirm_dialog.dart';
import 'package:artemis_business_os/core/widgets/data_card.dart';
import 'package:artemis_business_os/core/widgets/main_shell.dart';
import 'package:artemis_business_os/features/auth/application/auth_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class PaymentsListScreen extends ConsumerStatefulWidget {
  const PaymentsListScreen({super.key});

  @override
  ConsumerState<PaymentsListScreen> createState() => _PaymentsListScreenState();
}

class _PaymentsListScreenState extends ConsumerState<PaymentsListScreen> {
  List<dynamic> _allPayments = [];
  List<dynamic> _filteredPayments = [];
  bool _isLoading = true;
  String _statusFilter = 'ALL';
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
            (p['referenceNumber'] as String? ?? '').toLowerCase().contains(q) ||
            (p['salesOrderNumber'] as String? ?? '').toLowerCase().contains(q);
      }).toList();
    }

    setState(() => _filteredPayments = filtered);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BrandedAppBar(
        title: 'Payments',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadPayments,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.push('/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/payments/create');
          _loadPayments();
        },
        icon: const Icon(Icons.add),
        label: const Text('New Payment'),
        backgroundColor: AppTheme.successColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by customer, invoice, or reference...',
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
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (v) {
                setState(() => _searchQuery = v);
                _applyFilters();
              },
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _statusFilter == 'ALL',
                  onTap: () {
                    setState(() => _statusFilter = 'ALL');
                    _applyFilters();
                  },
                ),
                _FilterChip(
                  label: 'Pending',
                  selected: _statusFilter == 'PENDING',
                  onTap: () {
                    setState(() => _statusFilter = 'PENDING');
                    _applyFilters();
                  },
                ),
                _FilterChip(
                  label: 'Verified',
                  selected: _statusFilter == 'VERIFIED',
                  onTap: () {
                    setState(() => _statusFilter = 'VERIFIED');
                    _applyFilters();
                  },
                ),
                _FilterChip(
                  label: 'Rejected',
                  selected: _statusFilter == 'REJECTED',
                  onTap: () {
                    setState(() => _statusFilter = 'REJECTED');
                    _applyFilters();
                  },
                ),
              ],
            ),
          ),
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
              child: Row(
                children: [
                  Text(
                    '${_filteredPayments.length} payment${_filteredPayments.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.slate500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_filteredPayments.isEmpty) {
      return EmptyState(
        icon: Icons.payments_outlined,
        title: _searchQuery.isNotEmpty
            ? 'No payments match your search'
            : 'No payments yet',
        subtitle: _searchQuery.isNotEmpty
            ? 'Try a different search term'
            : 'Tap the + button to record your first payment',
        actionLabel: _searchQuery.isEmpty ? 'Record Payment' : null,
        onAction: _searchQuery.isEmpty
            ? () => context.push('/payments/create')
            : null,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPayments,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _filteredPayments.length,
        itemBuilder: (context, index) {
          final p = _filteredPayments[index] as Map<String, dynamic>;
          return _buildPaymentCard(p);
        },
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final status = payment['verificationStatus'] as String;
    final color = status == 'VERIFIED'
        ? AppTheme.successColor
        : status == 'REJECTED'
        ? AppTheme.dangerColor
        : AppTheme.warningColor;
    final icon = status == 'VERIFIED'
        ? Icons.verified
        : status == 'REJECTED'
        ? Icons.cancel
        : Icons.hourglass_top;

    final customerName = payment['customerName'] as String? ?? 'Unknown';
    final amount = (payment['amount'] as num?) ?? 0;
    final method = payment['paymentMethod'] as String? ?? 'CASH';
    final invoiceNum = payment['salesOrderNumber'] as String?;
    final refNum = payment['referenceNumber'] as String?;
    final dateStr = payment['paymentDate'] as String?;
    final dateLabel = dateStr != null
        ? DateFormat('MMM dd, HH:mm').format(DateTime.parse(dateStr).toLocal())
        : '';

    final isAdmin = ref.read(authNotifierProvider).user?.isAdmin ?? false;

    final badges = <Widget>[
      StatusBadge(label: status, color: color, icon: icon),
      StatusBadge(
        label: _methodLabel(method),
        color: AppTheme.slate600,
        icon: _methodIcon(method),
      ),
    ];

    final meta = <Widget>[
      MetaItem(icon: Icons.person_outline, label: customerName),
      if (dateLabel.isNotEmpty)
        MetaItem(icon: Icons.access_time, label: dateLabel),
      if (invoiceNum != null)
        MetaItem(icon: Icons.receipt_long, label: invoiceNum),
    ];

    final menuItems = <PopupMenuEntry<String>>[
      const PopupMenuItem<String>(
        value: 'view',
        child: Row(
          children: [
            Icon(Icons.visibility, size: 18, color: AppTheme.slate700),
            SizedBox(width: 8),
            Text('View details'),
          ],
        ),
      ),
      if (status != 'VERIFIED' && isAdmin)
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: AppTheme.dangerColor),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: AppTheme.dangerColor)),
            ],
          ),
        ),
      if (status == 'VERIFIED')
        const PopupMenuItem<String>(
          enabled: false,
          child: Row(
            children: [
              Icon(Icons.lock_outline, size: 18, color: AppTheme.slate400),
              SizedBox(width: 8),
              Text(
                'Verified (cannot delete)',
                style: TextStyle(color: AppTheme.slate400),
              ),
            ],
          ),
        ),
    ];

    return DataCard(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(Icons.payments, color: color, size: 20),
      ),
      title: refNum != null && refNum.isNotEmpty
          ? refNum
          : '#${(payment['id'] as String).substring(0, 8)}',
      subtitle: customerName,
      meta: meta,
      badges: badges,
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'ETB ${NumberFormat.decimalPattern().format(amount)}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppTheme.slate900,
            ),
          ),
        ],
      ),
      onTap: () => context.push('/payments/${payment['id']}'),
      menuBuilder: () => menuItems,
      onMenuSelected: (v) {
        if (v == 'view') {
          context.push('/payments/${payment['id']}');
        } else if (v == 'delete') {
          _deletePayment(payment);
        }
      },
    );
  }

  IconData _methodIcon(String m) {
    switch (m) {
      case 'CASH':
        return Icons.payments;
      case 'BANK_TRANSFER':
        return Icons.account_balance;
      case 'MOBILE_MONEY':
        return Icons.phone_android;
      case 'CHECK':
        return Icons.note_alt_outlined;
      default:
        return Icons.more_horiz;
    }
  }

  String _methodLabel(String m) {
    switch (m) {
      case 'CASH':
        return 'CASH';
      case 'BANK_TRANSFER':
        return 'BANK';
      case 'MOBILE_MONEY':
        return 'MOBILE';
      case 'CHECK':
        return 'CHECK';
      default:
        return m;
    }
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Payment deleted'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
      _loadPayments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(parseApiError(e))),
              ],
            ),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
        checkmarkColor: AppTheme.primaryColor,
        labelStyle: TextStyle(
          color: selected ? AppTheme.primaryColor : AppTheme.slate500,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
        side: BorderSide(
          color: selected
              ? AppTheme.primaryColor.withValues(alpha: 0.3)
              : AppTheme.slate200,
        ),
      ),
    );
  }
}
