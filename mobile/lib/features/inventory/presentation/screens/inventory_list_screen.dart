import 'package:artemis_business_os/core/providers.dart';
import 'package:artemis_business_os/core/theme/app_theme.dart';
import 'package:artemis_business_os/core/widgets/ui_pro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class InventoryListScreen extends ConsumerStatefulWidget {
  const InventoryListScreen({super.key});

  @override
  ConsumerState<InventoryListScreen> createState() =>
      _InventoryListScreenState();
}

class _InventoryListScreenState extends ConsumerState<InventoryListScreen> {
  List<dynamic> _allInventory = [];
  List<dynamic> _filteredInventory = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _categoryFilter = 'ALL';
  bool _lowStockOnly = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInventory() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('/inventory');
      setState(() {
        _allInventory = res.data as List<dynamic>;
        _isLoading = false;
        _applyFilters();
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    var filtered = List<dynamic>.from(_allInventory);
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((item) {
        return (item['productName'] as String).toLowerCase().contains(q) ||
            (item['productSku'] as String).toLowerCase().contains(q);
      }).toList();
    }
    if (_categoryFilter != 'ALL') {
      filtered = filtered
          .where((item) => item['categoryType'] == _categoryFilter)
          .toList();
    }
    if (_lowStockOnly) {
      filtered = filtered.where((item) => item['isLowStock'] == true).toList();
    }
    setState(() => _filteredInventory = filtered);
  }

  @override
  Widget build(BuildContext context) {
    final lowCount = _allInventory.where((i) => i['isLowStock'] == true).length;
    final totalValue = _allInventory.fold<double>(
      0,
      (sum, item) => sum + ((item['inventoryValue'] as num?) ?? 0).toDouble(),
    );

    return Scaffold(
      backgroundColor: AppTheme.slate50,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 180,
            backgroundColor: AppTheme.cyanColor,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: HeroHeader(
                gradient: AppTheme.gradientCyan,
                height: 180,
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
                              const Text(
                                'Inventory',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_allInventory.length} items tracked',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _HeaderStat(
                          icon: Icons.warning_rounded,
                          label: 'Low Stock',
                          value: '$lowCount',
                          highlight: lowCount > 0,
                        ),
                        const SizedBox(width: 8),
                        _HeaderStat(
                          icon: Icons.science_rounded,
                          label: 'Raw',
                          value:
                              '${_allInventory.where((i) => i['categoryType'] == 'RAW_MATERIAL').length}',
                        ),
                        const SizedBox(width: 8),
                        _HeaderStat(
                          icon: Icons.local_drink_rounded,
                          label: 'Finished',
                          value:
                              '${_allInventory.where((i) => i['categoryType'] == 'FINISHED_GOOD').length}',
                        ),
                      ],
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
                  hintText: 'Search by product or SKU...',
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
                    selected: _categoryFilter == 'ALL' && !_lowStockOnly,
                    onTap: () {
                      setState(() {
                        _categoryFilter = 'ALL';
                        _lowStockOnly = false;
                      });
                      _applyFilters();
                    },
                  ),
                  _ProChip(
                    label: 'Raw Materials',
                    selected: _categoryFilter == 'RAW_MATERIAL',
                    color: AppTheme.warningColor,
                    onTap: () {
                      setState(() {
                        _categoryFilter = 'RAW_MATERIAL';
                        _lowStockOnly = false;
                      });
                      _applyFilters();
                    },
                  ),
                  _ProChip(
                    label: 'Packaging',
                    selected: _categoryFilter == 'PACKAGING_MATERIAL',
                    color: AppTheme.infoColor,
                    onTap: () {
                      setState(() {
                        _categoryFilter = 'PACKAGING_MATERIAL';
                        _lowStockOnly = false;
                      });
                      _applyFilters();
                    },
                  ),
                  _ProChip(
                    label: 'Finished',
                    selected: _categoryFilter == 'FINISHED_GOOD',
                    color: AppTheme.successColor,
                    onTap: () {
                      setState(() {
                        _categoryFilter = 'FINISHED_GOOD';
                        _lowStockOnly = false;
                      });
                      _applyFilters();
                    },
                  ),
                  _ProChip(
                    label: 'Low Stock',
                    selected: _lowStockOnly,
                    color: AppTheme.dangerColor,
                    onTap: () {
                      setState(() => _lowStockOnly = !_lowStockOnly);
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
                Skeleton(height: 44, width: 44, radius: 10),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton(width: 120, height: 14),
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
    if (_filteredInventory.isEmpty) {
      return EmptyStatePro(
        icon: Icons.inventory_2_outlined,
        title: _searchQuery.isNotEmpty ? 'No matches' : 'No inventory yet',
        subtitle: _searchQuery.isNotEmpty
            ? 'Try a different search or filter'
            : 'Inventory appears here once stock is added',
        accentColor: AppTheme.cyanColor,
      );
    }
    return RefreshIndicator(
      color: AppTheme.cyanColor,
      onRefresh: _loadInventory,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filteredInventory.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildInventoryCard(
            _filteredInventory[i] as Map<String, dynamic>,
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryCard(Map<String, dynamic> item) {
    final type = item['categoryType'] as String? ?? 'UNKNOWN';
    final isLowStock = item['isLowStock'] == true;

    final (color, icon) = switch (type) {
      'RAW_MATERIAL' => (AppTheme.warningColor, Icons.science_rounded),
      'PACKAGING_MATERIAL' => (AppTheme.infoColor, Icons.inventory_2_rounded),
      'FINISHED_GOOD' => (AppTheme.successColor, Icons.local_drink_rounded),
      _ => (AppTheme.slate500, Icons.help_outline_rounded),
    };

    final qty = (item['currentQuantity'] as num? ?? 0).toDouble();
    final reorder = (item['reorderPoint'] as num? ?? 0).toDouble();
    final unit = item['unitOfMeasure'] as String? ?? 'units';
    final value = (item['inventoryValue'] as num? ?? 0).toDouble();
    final progress = reorder > 0 ? (qty / (reorder * 3)).clamp(0.0, 1.0) : 1.0;
    final progressColor = isLowStock ? AppTheme.dangerColor : color;

    return GlassCard(
      accentColor: color,
      onTap: () => context.push('/inventory/${item['id']}'),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.18),
                  color.withValues(alpha: 0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
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
                        item['productName'] as String? ?? 'Unknown',
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
                    if (isLowStock)
                      StatusPill(
                        label: 'LOW',
                        color: AppTheme.dangerColor,
                        icon: Icons.warning_rounded,
                        small: true,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'SKU ${item['productSku']}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.slate500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: AppTheme.slate100,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${qty.toStringAsFixed(0)} $unit',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: progressColor,
                      ),
                    ),
                    Text(
                      ' / reorder at ${reorder.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.slate500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'ETB ${NumberFormat.compactCurrency(symbol: '', decimalDigits: 0).format(value)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.slate500,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  const _HeaderStat({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: highlight ? 0.25 : 0.15),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: highlight ? AppTheme.warningColor : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: highlight ? Colors.white : Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.9),
              ),
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
