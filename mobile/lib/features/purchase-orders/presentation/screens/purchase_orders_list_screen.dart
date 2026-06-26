import 'package:artemis_business_os/core/network/api_errors.dart';
import 'package:artemis_business_os/core/providers.dart';
import 'package:artemis_business_os/core/theme/app_theme.dart';
import 'package:artemis_business_os/core/widgets/ui_pro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class PurchaseOrdersListScreen extends ConsumerStatefulWidget {
  final String? supplierIdFilter;
  const PurchaseOrdersListScreen({super.key, this.supplierIdFilter});

  @override
  ConsumerState<PurchaseOrdersListScreen> createState() =>
      _PurchaseOrdersListScreenState();
}

class _PurchaseOrdersListScreenState
    extends ConsumerState<PurchaseOrdersListScreen> {
  List<dynamic> _orders = [];
  List<dynamic> _filtered = [];
  bool _isLoading = true;
  String _statusFilter = 'ALL';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final params = <String, dynamic>{};
      if (widget.supplierIdFilter != null) {
        params['supplierId'] = widget.supplierIdFilter;
      }
      final res = await api.get(
        '/purchase-orders',
        queryParameters: params.isEmpty ? null : params,
      );
      setState(() {
        _orders = res.data as List<dynamic>;
        _isLoading = false;
        _applyFilters();
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    var filtered = List<dynamic>.from(_orders);
    if (_statusFilter != 'ALL') {
      filtered = filtered.where((o) => o['status'] == _statusFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((o) {
        return (o['poNumber'] as String).toLowerCase().contains(q) ||
            (o['supplierName'] as String).toLowerCase().contains(q);
      }).toList();
    }
    setState(() => _filtered = filtered);
  }

  @override
  Widget build(BuildContext context) {
    final totalValue = _orders.fold<double>(
      0,
      (sum, o) => sum + ((o['total'] as num?) ?? 0).toDouble(),
    );
    final pendingCount = _orders
        .where((o) => o['status'] != 'RECEIVED' && o['status'] != 'CANCELLED')
        .length;

    return Scaffold(
      backgroundColor: AppTheme.slate50,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 170,
            backgroundColor: const Color(0xFF0F766E),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: HeroHeader(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                ),
                height: 170,
                glow: true,
                padding: const EdgeInsets.fromLTRB(20, 64, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.supplierIdFilter != null
                                    ? 'Supplier POs'
                                    : 'Purchase Orders',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.supplierIdFilter != null
                                    ? 'For this supplier'
                                    : 'Orders to suppliers',
                                style: const TextStyle(
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
                              'Total Value',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'ETB ${NumberFormat.compactCurrency(symbol: '', decimalDigits: 0).format(totalValue)}',
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
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.hourglass_top_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$pendingCount awaiting receipt',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
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
                  hintText: 'Search by PO # or supplier...',
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
                    label: 'Sent',
                    selected: _statusFilter == 'SENT',
                    color: AppTheme.infoColor,
                    onTap: () {
                      setState(() => _statusFilter = 'SENT');
                      _applyFilters();
                    },
                  ),
                  _ProChip(
                    label: 'Partial',
                    selected: _statusFilter == 'PARTIALLY_RECEIVED',
                    color: AppTheme.warningColor,
                    onTap: () {
                      setState(() => _statusFilter = 'PARTIALLY_RECEIVED');
                      _applyFilters();
                    },
                  ),
                  _ProChip(
                    label: 'Received',
                    selected: _statusFilter == 'RECEIVED',
                    color: AppTheme.successColor,
                    onTap: () {
                      setState(() => _statusFilter = 'RECEIVED');
                      _applyFilters();
                    },
                  ),
                  _ProChip(
                    label: 'Cancelled',
                    selected: _statusFilter == 'CANCELLED',
                    color: AppTheme.dangerColor,
                    onTap: () {
                      setState(() => _statusFilter = 'CANCELLED');
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
          await context.push('/purchase-orders/new');
          _load();
        },
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New PO'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: 4,
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
                      Skeleton(width: 140, height: 14),
                      SizedBox(height: 6),
                      Skeleton(width: 200, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_filtered.isEmpty) {
      return EmptyStatePro(
        icon: Icons.shopping_bag_rounded,
        title: _searchQuery.isNotEmpty
            ? 'No matches'
            : 'No purchase orders yet',
        subtitle: _searchQuery.isNotEmpty
            ? 'Try a different search term'
            : 'Create a PO to order raw materials from suppliers',
        accentColor: const Color(0xFF0F766E),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFF0F766E),
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filtered.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildPOCard(_filtered[i]),
        ),
      ),
    );
  }

  Widget _buildPOCard(Map<String, dynamic> o) {
    final status = o['status'] as String? ?? 'DRAFT';
    final (color, icon, label) = switch (status) {
      'RECEIVED' => (
        AppTheme.successColor,
        Icons.check_circle_rounded,
        'RECEIVED',
      ),
      'PARTIALLY_RECEIVED' => (
        AppTheme.warningColor,
        Icons.hourglass_top_rounded,
        'PARTIAL',
      ),
      'CANCELLED' => (AppTheme.dangerColor, Icons.block_rounded, 'CANCELLED'),
      _ => (AppTheme.infoColor, Icons.send_rounded, 'SENT'),
    };

    return GlassCard(
      accentColor: color,
      onTap: () => context.push('/purchase-orders/${o['id']}'),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(icon, color: color, size: 20),
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
                            o['poNumber'] as String? ?? '',
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
                        StatusPill(label: label, color: color, small: true),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      o['supplierName'] as String? ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.slate600,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      o['orderDate'] != null
                          ? DateFormat('MMM dd, yyyy').format(
                              DateTime.parse(
                                o['orderDate'] as String,
                              ).toLocal(),
                            )
                          : '',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.slate500,
                      ),
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
                    NumberFormat.decimalPattern().format(o['total'] ?? 0),
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
