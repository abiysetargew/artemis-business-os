import 'package:artemis_business_os/core/network/api_errors.dart';
import 'package:artemis_business_os/core/providers.dart';
import 'package:artemis_business_os/core/theme/app_theme.dart';
import 'package:artemis_business_os/core/widgets/confirm_dialog.dart';
import 'package:artemis_business_os/core/widgets/ui_pro.dart';
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
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        return (p['customerName'] as String? ?? '').toLowerCase().contains(q) ||
            (p['referenceNumber'] as String? ?? '').toLowerCase().contains(q) ||
            (p['salesOrderNumber'] as String? ?? '').toLowerCase().contains(q);
      }).toList();
    }
    setState(() => _filteredPayments = filtered);
  }

  Future<void> _deletePayment(Map<String, dynamic> payment) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Payment?',
      message:
          'Delete payment of ETB ${(payment['amount'] as num).toStringAsFixed(2)}? Cannot be undone.',
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

  Future<void> _verifyPayment(Map<String, dynamic> payment) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.patch(
        '/payments/${payment['id']}',
        data: {'verificationStatus': 'VERIFIED'},
      );
      if (mounted) {
        showAppSnackBar(context, message: 'Payment verified', isSuccess: true);
      }
      _loadPayments();
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, message: parseApiError(e), isError: true);
      }
    }
  }

  Future<void> _rejectPayment(Map<String, dynamic> payment) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Reject Payment?',
      message: 'Reject this payment? It will not affect customer balance.',
      confirmLabel: 'Reject',
      type: ConfirmDialogType.destructive,
    );
    if (!confirmed) return;
    try {
      final api = ref.read(apiClientProvider);
      await api.patch(
        '/payments/${payment['id']}',
        data: {'verificationStatus': 'REJECTED'},
      );
      if (mounted) {
        showAppSnackBar(context, message: 'Payment rejected', isSuccess: true);
      }
      _loadPayments();
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, message: parseApiError(e), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = _allPayments.fold<double>(
      0,
      (sum, p) => sum + ((p['amount'] as num?) ?? 0).toDouble(),
    );
    final pendingCount = _allPayments
        .where((p) => p['verificationStatus'] == 'PENDING')
        .length;

    return Scaffold(
      backgroundColor: AppTheme.slate50,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 160,
            backgroundColor: AppTheme.successColor,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: HeroHeader(
                gradient: AppTheme.gradientSuccess,
                height: 160,
                glow: true,
                padding: const EdgeInsets.fromLTRB(20, 64, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Payments',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Collections & receipts',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Total Collected',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'ETB ${NumberFormat.compactCurrency(symbol: '', decimalDigits: 0).format(totalAmount)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (pendingCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.hourglass_top_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$pendingCount payment${pendingCount == 1 ? '' : 's'} awaiting verification',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by customer, invoice, or reference...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
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
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _ProChip(
                    label: 'All',
                    selected: _statusFilter == 'ALL',
                    onTap: () {
                      setState(() => _statusFilter = 'ALL');
                      _applyFilters();
                    },
                  ),
                  _ProChip(
                    label: 'Pending',
                    selected: _statusFilter == 'PENDING',
                    color: AppTheme.warningColor,
                    onTap: () {
                      setState(() => _statusFilter = 'PENDING');
                      _applyFilters();
                    },
                  ),
                  _ProChip(
                    label: 'Verified',
                    selected: _statusFilter == 'VERIFIED',
                    color: AppTheme.successColor,
                    onTap: () {
                      setState(() => _statusFilter = 'VERIFIED');
                      _applyFilters();
                    },
                  ),
                  _ProChip(
                    label: 'Rejected',
                    selected: _statusFilter == 'REJECTED',
                    color: AppTheme.dangerColor,
                    onTap: () {
                      setState(() => _statusFilter = 'REJECTED');
                      _applyFilters();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/payments/create');
          _loadPayments();
        },
        backgroundColor: AppTheme.successColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Payment'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: 5,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            child: Row(
              children: const [
                Skeleton(height: 44, width: 44, radius: 12),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton(width: 100, height: 14),
                      SizedBox(height: 6),
                      Skeleton(width: 180, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_filteredPayments.isEmpty) {
      return EmptyStatePro(
        icon: Icons.payments_outlined,
        title: _searchQuery.isNotEmpty ? 'No matches' : 'No payments yet',
        subtitle: _searchQuery.isNotEmpty
            ? 'Try a different search term'
            : 'Tap + to record your first payment',
        accentColor: AppTheme.successColor,
      );
    }
    return RefreshIndicator(
      color: AppTheme.successColor,
      onRefresh: _loadPayments,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filteredPayments.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildPaymentCard(_filteredPayments[i]),
        ),
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final status = payment['verificationStatus'] as String? ?? 'PENDING';
    final (color, icon, label) = switch (status) {
      'VERIFIED' => (AppTheme.successColor, Icons.verified_rounded, 'VERIFIED'),
      'REJECTED' => (AppTheme.dangerColor, Icons.cancel_rounded, 'REJECTED'),
      _ => (AppTheme.warningColor, Icons.hourglass_top_rounded, 'PENDING'),
    };

    final method = payment['paymentMethod'] as String? ?? 'CASH';
    final (methodColor, methodIcon, methodLabel) = switch (method) {
      'CASH' => (AppTheme.successColor, Icons.payments_rounded, 'CASH'),
      'BANK_TRANSFER' => (
        AppTheme.infoColor,
        Icons.account_balance_rounded,
        'BANK',
      ),
      'MOBILE_MONEY' => (
        AppTheme.warningColor,
        Icons.phone_android_rounded,
        'MOBILE',
      ),
      'CHECK' => (AppTheme.slate600, Icons.note_alt_rounded, 'CHECK'),
      _ => (AppTheme.slate500, Icons.more_horiz_rounded, method),
    };

    final amount = (payment['amount'] as num? ?? 0).toDouble();
    final customerName = payment['customerName'] as String? ?? 'Unknown';
    final refNum = payment['referenceNumber'] as String?;
    final invoiceNum = payment['salesOrderNumber'] as String?;
    final dateStr = payment['paymentDate'] as String?;
    final dateLabel = dateStr != null
        ? DateFormat('MMM dd · HH:mm').format(DateTime.parse(dateStr).toLocal())
        : '';

    final isAdmin = ref.read(authNotifierProvider).user?.isAdmin ?? false;
    final isPending = status == 'PENDING';

    return GlassCard(
      accentColor: color,
      onTap: () => context.push('/payments/${payment['id']}'),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.18),
                      color.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            customerName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.slate900,
                              letterSpacing: -0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        StatusPill(
                          label: label,
                          color: color,
                          icon: icon,
                          small: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(methodIcon, size: 11, color: methodColor),
                        const SizedBox(width: 3),
                        Text(
                          methodLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: methodColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: AppTheme.slate300,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            dateLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.slate500,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ETB',
                    style: TextStyle(
                      fontSize: 9,
                      color: AppTheme.slate500,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    NumberFormat.decimalPattern().format(amount),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.slate900,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (refNum != null || invoiceNum != null) ...[
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppTheme.slate100),
            const SizedBox(height: 8),
            Row(
              children: [
                if (invoiceNum != null) ...[
                  const Icon(
                    Icons.receipt_long_rounded,
                    size: 12,
                    color: AppTheme.slate400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    invoiceNum,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.slate600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (refNum != null) ...[
                  const Icon(
                    Icons.tag_rounded,
                    size: 12,
                    color: AppTheme.slate400,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      refNum,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.slate600,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],
          if (isPending && isAdmin) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectPayment(payment),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.dangerColor,
                      side: BorderSide(
                        color: AppTheme.dangerColor.withValues(alpha: 0.3),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _verifyPayment(payment),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Verify'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ProChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ProChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = AppTheme.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = color;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        child: AnimatedContainer(
          duration: AppTheme.durBase,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? c : Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            border: Border.all(
              color: selected ? c : AppTheme.slate200,
              width: 1.2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: c.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.slate600,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
