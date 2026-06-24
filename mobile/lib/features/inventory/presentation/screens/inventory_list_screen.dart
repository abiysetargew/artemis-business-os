import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:artemis_business_os/core/providers.dart';
import 'package:artemis_business_os/core/theme/app_theme.dart';
import 'package:artemis_business_os/core/widgets/main_shell.dart';

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
  String _categoryFilter =
      'ALL'; // ALL, RAW_MATERIAL, PACKAGING_MATERIAL, FINISHED_GOOD
  bool _lowStockOnly = false;

  @override
  void initState() {
    super.initState();
    _loadInventory();
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
    return Scaffold(
      appBar: BrandedAppBar(
        title: 'Inventory',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadInventory,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.push('/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by product or SKU...',
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
                  current: _categoryFilter,
                  onTap: (v) {
                    setState(() => _categoryFilter = v);
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Raw Materials',
                  value: 'RAW_MATERIAL',
                  current: _categoryFilter,
                  onTap: (v) {
                    setState(() => _categoryFilter = v);
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Packaging',
                  value: 'PACKAGING_MATERIAL',
                  current: _categoryFilter,
                  onTap: (v) {
                    setState(() => _categoryFilter = v);
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Finished Goods',
                  value: 'FINISHED_GOOD',
                  current: _categoryFilter,
                  onTap: (v) {
                    setState(() => _categoryFilter = v);
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Low Stock Only'),
                  selected: _lowStockOnly,
                  onSelected: (v) {
                    setState(() => _lowStockOnly = v);
                    _applyFilters();
                  },
                  avatar: const Icon(Icons.warning_amber, size: 16),
                  selectedColor: Colors.red.shade100,
                ),
              ],
            ),
          ),
          if (!_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              width: double.infinity,
              child: Text(
                '${_filteredInventory.length} item${_filteredInventory.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Expanded(
            child: _isLoading
                ? _buildShimmerLoading()
                : _filteredInventory.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadInventory,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _filteredInventory.length,
                      itemBuilder: (context, index) {
                        return _buildInventoryCard(_filteredInventory[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: 8,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 100,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'No items found' : 'No inventory yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search or filters'
                : 'Inventory will appear here once added',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(Map<String, dynamic> item) {
    final type = item['categoryType'] as String? ?? 'UNKNOWN';
    final isLowStock = item['isLowStock'] == true;
    return Card(
      child: InkWell(
        onTap: () {
          context.push('/inventory/${item['id']}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _getCategoryColor(
                  type,
                ).withValues(alpha: 0.15),
                child: Icon(
                  _getCategoryIcon(type),
                  color: _getCategoryColor(type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['productName'] as String? ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'SKU: ${item['productSku']}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    if (isLowStock)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'LOW STOCK',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${item['currentQuantity']} ${item['unitOfMeasure']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'ETB ${(item['inventoryValue'] as num).toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String type) {
    switch (type) {
      case 'RAW_MATERIAL':
        return Colors.orange;
      case 'PACKAGING_MATERIAL':
        return Colors.blue;
      case 'FINISHED_GOOD':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String type) {
    switch (type) {
      case 'RAW_MATERIAL':
        return Icons.science;
      case 'PACKAGING_MATERIAL':
        return Icons.inventory_2;
      case 'FINISHED_GOOD':
        return Icons.local_drink;
      default:
        return Icons.help;
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
