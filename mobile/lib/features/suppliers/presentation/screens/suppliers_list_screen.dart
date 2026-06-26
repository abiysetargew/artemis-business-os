import 'package:artemis_business_os/core/network/api_errors.dart';
import 'package:artemis_business_os/core/providers.dart';
import 'package:artemis_business_os/core/theme/app_theme.dart';
import 'package:artemis_business_os/core/widgets/ui_pro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class SuppliersListScreen extends ConsumerStatefulWidget {
  const SuppliersListScreen({super.key});

  @override
  ConsumerState<SuppliersListScreen> createState() =>
      _SuppliersListScreenState();
}

class _SuppliersListScreenState extends ConsumerState<SuppliersListScreen> {
  List<dynamic> _suppliers = [];
  List<dynamic> _filtered = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filter = 'ALL';
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
      final res = await api.get('/suppliers');
      setState(() {
        _suppliers = res.data as List<dynamic>;
        _isLoading = false;
        _applyFilters();
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    var filtered = List<dynamic>.from(_suppliers);
    if (_filter == 'ACTIVE') {
      filtered = filtered.where((s) => s['isActive'] == true).toList();
    } else if (_filter == 'INACTIVE') {
      filtered = filtered.where((s) => s['isActive'] == false).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((s) {
        return (s['name'] as String).toLowerCase().contains(q) ||
            (s['phone'] as String? ?? '').toLowerCase().contains(q) ||
            (s['city'] as String? ?? '').toLowerCase().contains(q);
      }).toList();
    }
    setState(() => _filtered = filtered);
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _suppliers.where((s) => s['isActive'] == true).length;
    final totalSpent = _suppliers.fold<double>(
      0,
      (sum, s) => sum + ((s['totalSpent'] as num?) ?? 0).toDouble(),
    );

    return Scaffold(
      backgroundColor: AppTheme.slate50,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 170,
            backgroundColor: AppTheme.warningColor,
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
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Suppliers',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Raw material vendors',
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
                              'Total Spent',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'ETB ${NumberFormat.compactCurrency(symbol: '', decimalDigits: 0).format(totalSpent)}',
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$activeCount active supplier${activeCount == 1 ? '' : 's'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(
                              Icons.refresh_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            onPressed: _load,
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
                  hintText: 'Search by name, phone, or city...',
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
                    selected: _filter == 'ALL',
                    onTap: () {
                      setState(() => _filter = 'ALL');
                      _applyFilters();
                    },
                  ),
                  _ProChip(
                    label: 'Active',
                    selected: _filter == 'ACTIVE',
                    color: AppTheme.successColor,
                    onTap: () {
                      setState(() => _filter = 'ACTIVE');
                      _applyFilters();
                    },
                  ),
                  _ProChip(
                    label: 'Inactive',
                    selected: _filter == 'INACTIVE',
                    color: AppTheme.slate500,
                    onTap: () {
                      setState(() => _filter = 'INACTIVE');
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
          await context.push('/suppliers/new');
          _load();
        },
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Supplier'),
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
        icon: Icons.local_shipping_rounded,
        title: _searchQuery.isNotEmpty ? 'No matches' : 'No suppliers yet',
        subtitle: _searchQuery.isNotEmpty
            ? 'Try a different search term'
            : 'Add your first supplier to track raw material vendors',
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
          child: _buildSupplierCard(_filtered[i]),
        ),
      ),
    );
  }

  Widget _buildSupplierCard(Map<String, dynamic> s) {
    final isActive = s['isActive'] == true;
    final accent = isActive ? const Color(0xFF0F766E) : AppTheme.slate500;
    final name = s['name'] as String? ?? 'Unknown';
    final phone = s['phone'] as String?;
    final city = s['city'] as String?;
    final region = s['region'] as String?;
    final totalOrders = (s['totalOrders'] as num? ?? 0).toInt();
    final totalSpent = (s['totalSpent'] as num? ?? 0).toDouble();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return GlassCard(
      accentColor: accent,
      onTap: () => context.push('/suppliers/${s['id']}'),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent.withValues(alpha: 0.18),
                  accent.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: TextStyle(
                color: accent,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
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
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.slate900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    StatusPill(
                      label: isActive ? 'ACTIVE' : 'INACTIVE',
                      color: isActive
                          ? AppTheme.successColor
                          : AppTheme.slate500,
                      small: true,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (phone != null && phone.isNotEmpty) ...[
                      const Icon(
                        Icons.phone_rounded,
                        size: 11,
                        color: AppTheme.slate400,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        phone,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.slate500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (city != null && city.isNotEmpty)
                      Flexible(
                        child: Text(
                          '$city',
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
                if (totalOrders > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.shopping_bag_rounded,
                        size: 11,
                        color: AppTheme.slate400,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '$totalOrders PO${totalOrders == 1 ? '' : 's'} · ETB ${NumberFormat.compactCurrency(symbol: '', decimalDigits: 0).format(totalSpent)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.slate600,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
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
