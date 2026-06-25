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
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSales() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/sales');
      setState(() {
        _allSales = response.data as List<dynamic>;
        _isLoading = false;
        _applyFilters();
      });
    } catch (e) {
      setState(() => _isLoading = false);
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
          'Cancel ${sale['orderNumber']}? This reverses the inventory deduction. Cannot be undone.',
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
      backgroundColor: AppTheme.slate50,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 140,
            backgroundColor: AppTheme.primaryColor,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: HeroHeader(
                gradient: AppTheme.gradientPrimary,
                height: 140,
                glow: true,
                padding: const EdgeInsets.fromLTRB(20, 64, 20, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Sales Orders',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_allSales.length} total orders',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search_rounded),
                      onPressed: () {
                        // focus search
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: _loadSales,
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
                  hintText: 'Search by order # or customer...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _search = '');
                            _applyFilters();
                          },
                        )
                      : null,
                ),
                onChanged: (v) {
                  setState(() => _search = v);
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
                    selected: _filter == 'ALL',
                    onTap: () => _setFilter('ALL'),
                  ),
                  _ProChip(
                    label: 'Cash',
                    selected: _filter == 'CASH_SALE',
                    color: AppTheme.infoColor,
                    onTap: () => _setFilter('CASH_SALE'),
                  ),
                  _ProChip(
                    label: 'Credit',
                    selected: _filter == 'CREDIT_SALE',
                    color: AppTheme.warningColor,
                    onTap: () => _setFilter('CREDIT_SALE'),
                  ),
                  _ProChip(
                    label: 'Cancelled',
                    selected: _filter == 'CANCELLED',
                    color: AppTheme.slate500,
                    onTap: () => _setFilter('CANCELLED'),
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
          await context.push('/sales/create');
          _loadSales();
        },
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Sale'),
      ),
    );
  }

  void _setFilter(String f) {
    setState(() => _filter = f);
    _applyFilters();
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: 5,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Skeleton(height: 40, width: 40, radius: 10, circle: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Skeleton(width: 100, height: 14),
                      SizedBox(height: 6),
                      Skeleton(width: 160, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_filteredSales.isEmpty) {
      return EmptyStatePro(
        icon: Icons.point_of_sale_rounded,
        title: _search.isNotEmpty ? 'No matches' : 'No sales yet',
        subtitle: _search.isNotEmpty
            ? 'Try a different search term'
            : 'Tap the + button to record your first sale',
        actionLabel: _search.isEmpty ? 'New Sale' : null,
        onAction: _search.isEmpty ? () => context.push('/sales/create') : null,
        accentColor: AppTheme.primaryColor,
      );
    }
    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: _loadSales,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filteredSales.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildSaleCard(_filteredSales[i] as Map<String, dynamic>),
        ),
      ),
    );
  }

  Widget _buildSaleCard(Map<String, dynamic> sale) {
    final isPaid = sale['paymentStatus'] == 'PAID';
    final isCancelled = sale['isCancelled'] == true;
    final isCash = sale['orderType'] == 'CASH_SALE';
    final isAdmin = ref.read(authNotifierProvider).user?.isAdmin ?? false;

    Color accent;
    Color avatarBg;
    IconData avatarIcon;
    if (isCancelled) {
      accent = AppTheme.slate500;
      avatarBg = AppTheme.slate100;
      avatarIcon = Icons.block_rounded;
    } else if (isPaid) {
      accent = AppTheme.successColor;
      avatarBg = AppTheme.successLight;
      avatarIcon = Icons.check_circle_rounded;
    } else if (isCash) {
      accent = AppTheme.infoColor;
      avatarBg = AppTheme.infoLight;
      avatarIcon = Icons.payments_rounded;
    } else {
      accent = AppTheme.warningColor;
      avatarBg = AppTheme.warningLight;
      avatarIcon = Icons.credit_card_rounded;
    }

    final orderNumber = sale['orderNumber'] as String? ?? '';
    final customerName = sale['customerName'] as String? ?? 'Unknown';
    final totalAmount = (sale['totalAmount'] as num?) ?? 0;
    final dateStr = sale['orderDate'] as String?;
    final dateLabel = dateStr != null
        ? DateFormat('MMM dd · HH:mm').format(DateTime.parse(dateStr).toLocal())
        : '';
    final region = sale['region'] as String?;
    final city = sale['city'] as String?;

    return Dismissible(
      key: ValueKey(sale['id']),
      direction: isAdmin && !isCancelled && !isPaid
          ? DismissDirection.endToStart
          : DismissDirection.none,
      confirmDismiss: (_) async {
        await _cancelOrder(sale);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppTheme.dangerColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      child: GlassCard(
        accentColor: accent,
        onTap: () => context.push('/sales/${sale['id']}'),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: avatarBg,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(avatarIcon, color: accent, size: 22),
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
                          orderNumber,
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
                      const SizedBox(width: 8),
                      StatusPill(
                        label: isPaid
                            ? 'PAID'
                            : isCancelled
                            ? 'CANCELLED'
                            : isCash
                            ? 'CASH'
                            : 'PENDING',
                        color: accent,
                        icon: avatarIcon,
                        small: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    customerName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.slate700,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 11,
                        color: AppTheme.slate400,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        dateLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.slate500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (region != null && city != null) ...[
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
                            '$city, $region',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.slate500,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
                  NumberFormat.decimalPattern().format(totalAmount),
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
      child: Material(
        color: Colors.transparent,
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
      ),
    );
  }
}
