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

class SalesListScreen extends ConsumerStatefulWidget {
  const SalesListScreen({super.key});

  @override
  ConsumerState<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends ConsumerState<SalesListScreen> {
  List<dynamic> _allSales = [];
  List<dynamic> _filteredSales = [];
  bool _isLoading = true;
  String _filter = 'ALL';
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/sales');
      setState(() {
        _allSales = response.data as List<dynamic>;
        _isLoading = false;
        _applyFilters();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    var filtered = List<dynamic>.from(_allSales);
    if (_filter != 'ALL') {
      filtered = filtered.where((s) {
        final sale = s as Map<String, dynamic>;
        return _filter == 'CANCELLED'
            ? sale['isCancelled'] == true
            : sale['orderType'] == _filter;
      }).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      filtered = filtered.where((s) {
        final sale = s as Map<String, dynamic>;
        final orderNum = (sale['orderNumber'] as String? ?? '').toLowerCase();
        final customer = (sale['customerName'] as String? ?? '').toLowerCase();
        return orderNum.contains(q) || customer.contains(q);
      }).toList();
    }
    setState(() => _filteredSales = filtered);
  }

  Future<void> _cancelOrder(Map<String, dynamic> sale) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Cancel Order?',
      message:
          'Cancel ${sale['orderNumber']}? This will reverse the inventory deduction and any customer balance change. Cannot be undone.',
      confirmLabel: 'Cancel Order',
      type: ConfirmDialogType.destructive,
    );
    if (!confirmed) return;
    try {
      final api = ref.read(apiClientProvider);
      await api.delete('/sales/${sale['id']}');
      if (mounted) {
        showAppSnackBar(context, message: 'Order cancelled', isSuccess: true);
      }
      _loadSales();
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, message: parseApiError(e), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BrandedAppBar(
        title: 'Sales',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadSales,
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
          await context.push('/sales/create');
          _loadSales();
        },
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Sale'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by order # or customer...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _search = '');
                          _applyFilters();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (v) {
                setState(() => _search = v);
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
                _Chip(
                  label: 'All',
                  selected: _filter == 'ALL',
                  onTap: () {
                    setState(() => _filter = 'ALL');
                    _applyFilters();
                  },
                ),
                _Chip(
                  label: 'Cash',
                  selected: _filter == 'CASH_SALE',
                  onTap: () {
                    setState(() => _filter = 'CASH_SALE');
                    _applyFilters();
                  },
                ),
                _Chip(
                  label: 'Credit',
                  selected: _filter == 'CREDIT_SALE',
                  onTap: () {
                    setState(() => _filter = 'CREDIT_SALE');
                    _applyFilters();
                  },
                ),
                _Chip(
                  label: 'Cancelled',
                  selected: _filter == 'CANCELLED',
                  onTap: () {
                    setState(() => _filter = 'CANCELLED');
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
                    '${_filteredSales.length} sale${_filteredSales.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_filteredSales.isEmpty) {
      return EmptyState(
        icon: Icons.point_of_sale,
        title: _search.isNotEmpty
            ? 'No sales match your search'
            : 'No sales yet',
        subtitle: _search.isNotEmpty
            ? 'Try a different search term'
            : 'Tap the + button to record your first sale',
        actionLabel: _search.isEmpty ? 'Create Sale' : null,
        onAction: _search.isEmpty ? () => context.push('/sales/create') : null,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSales,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _filteredSales.length,
        itemBuilder: (context, index) {
          final sale = _filteredSales[index] as Map<String, dynamic>;
          return _buildSaleCard(sale);
        },
      ),
    );
  }

  Widget _buildSaleCard(Map<String, dynamic> sale) {
    final isPaid = sale['paymentStatus'] == 'PAID';
    final isCancelled = sale['isCancelled'] == true;
    final isCash = sale['orderType'] == 'CASH_SALE';
    final isAdmin = ref.read(authNotifierProvider).user?.isAdmin ?? false;

    final orderNumber = sale['orderNumber'] as String? ?? '';
    final customerName = sale['customerName'] as String? ?? 'Unknown';
    final totalAmount = (sale['totalAmount'] as num?) ?? 0;
    final dateStr = sale['orderDate'] as String?;
    final dateLabel = dateStr != null
        ? DateFormat('MMM dd, HH:mm').format(DateTime.parse(dateStr).toLocal())
        : '';

    Color avatarColor;
    IconData avatarIcon;
    if (isCancelled) {
      avatarColor = Colors.grey;
      avatarIcon = Icons.block;
    } else if (isPaid) {
      avatarColor = const Color(0xFF059669);
      avatarIcon = Icons.check_circle;
    } else if (isCash) {
      avatarColor = const Color(0xFF2563EB);
      avatarIcon = Icons.payments;
    } else {
      avatarColor = const Color(0xFFD97706);
      avatarIcon = Icons.credit_card;
    }

    final badges = <Widget>[
      if (isCash)
        StatusBadge(
          label: 'CASH',
          color: const Color(0xFF2563EB),
          icon: Icons.payments,
        )
      else
        StatusBadge(
          label: 'CREDIT',
          color: const Color(0xFFD97706),
          icon: Icons.credit_card,
        ),
      if (isCancelled)
        StatusBadge(label: 'CANCELLED', color: Colors.grey, icon: Icons.block)
      else if (isPaid)
        StatusBadge(
          label: 'PAID',
          color: const Color(0xFF059669),
          icon: Icons.check_circle,
        )
      else
        StatusBadge(
          label: 'PENDING',
          color: const Color(0xFFD97706),
          icon: Icons.schedule,
        ),
    ];

    final meta = <Widget>[
      MetaItem(icon: Icons.person_outline, label: customerName),
      if (dateLabel.isNotEmpty)
        MetaItem(icon: Icons.access_time, label: dateLabel),
    ];

    final menuItems = <PopupMenuEntry<String>>[
      if (!isCancelled && !isPaid && isAdmin)
        const PopupMenuItem<String>(
          value: 'cancel',
          child: Row(
            children: [
              Icon(Icons.block, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Cancel order', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      if (isCancelled || isPaid)
        const PopupMenuItem<String>(
          enabled: false,
          child: Row(
            children: [
              Icon(Icons.lock, size: 18, color: Colors.grey),
              SizedBox(width: 8),
              Text('Cannot cancel', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
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
    ];

    return DataCard(
      leading: CircleAvatar(
        backgroundColor: avatarColor.withValues(alpha: 0.15),
        child: Icon(avatarIcon, color: avatarColor, size: 20),
      ),
      title: orderNumber,
      subtitle: customerName,
      meta: meta,
      badges: badges,
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'ETB ${NumberFormat.decimalPattern().format(totalAmount)}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
      onTap: () {
        // Future: navigate to sale detail
      },
      menuBuilder: () => menuItems,
      onMenuSelected: (v) {
        if (v == 'cancel') _cancelOrder(sale);
      },
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
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
          color: selected ? AppTheme.primaryColor : const Color(0xFF64748B),
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
        side: BorderSide(
          color: selected
              ? AppTheme.primaryColor.withValues(alpha: 0.3)
              : const Color(0xFFE2E8F0),
        ),
      ),
    );
  }
}
