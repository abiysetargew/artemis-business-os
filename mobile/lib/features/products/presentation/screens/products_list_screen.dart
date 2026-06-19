import 'package:artemis_business_os/core/network/api_errors.dart';
import 'package:artemis_business_os/core/providers.dart';
import 'package:artemis_business_os/core/theme/app_theme.dart';
import 'package:artemis_business_os/core/widgets/confirm_dialog.dart';
import 'package:artemis_business_os/features/auth/application/auth_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

class ProductsListScreen extends ConsumerStatefulWidget {
  const ProductsListScreen({super.key});

  @override
  ConsumerState<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends ConsumerState<ProductsListScreen> {
  List<dynamic> _products = [];
  String? _filterCategoryId;
  String? _filterType;
  final _searchController = TextEditingController();
  String _search = '';
  bool _isLoading = true;
  String? _error;

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

  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Product?',
      message:
          'Are you sure you want to delete "${product['name']}"? This cannot be undone. If the product has inventory, sales, or production history, the delete will fail.',
      confirmLabel: 'Delete',
      type: ConfirmDialogType.destructive,
    );
    if (!confirmed) return;
    try {
      final api = ref.read(apiClientProvider);
      await api.delete('/products/${product['id']}');
      if (mounted) {
        showAppSnackBar(context, message: 'Product deleted', isSuccess: true);
      }
      _load();
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, message: parseApiError(e), isError: true);
      }
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final results = await Future.wait<dynamic>([
        api.get(
          '/products',
          queryParameters: {
            if (_filterCategoryId != null) 'categoryId': _filterCategoryId,
            if (_filterType != null) 'type': _filterType,
            if (_search.isNotEmpty) 'search': _search,
          },
        ),
        api.get('/products/categories'),
      ]);
      setState(() {
        _products = results[0].data as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = parseApiError(e);
        _isLoading = false;
      });
    }
  }

  Color _typeColor(String? type) {
    switch (type) {
      case 'FINISHED_GOOD':
        return Colors.orange;
      case 'RAW_MATERIAL':
        return Colors.green;
      case 'PACKAGING_MATERIAL':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/products/new');
          _load();
        },
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Product'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or SKU...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                          _load();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onSubmitted: (v) {
                setState(() => _search = v);
                _load();
              },
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _filterType == null,
                  onSelected: (_) {
                    setState(() => _filterType = null);
                    _load();
                  },
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('Finished'),
                  selected: _filterType == 'FINISHED_GOOD',
                  onSelected: (_) {
                    setState(() => _filterType = 'FINISHED_GOOD');
                    _load();
                  },
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('Raw'),
                  selected: _filterType == 'RAW_MATERIAL',
                  onSelected: (_) {
                    setState(() => _filterType = 'RAW_MATERIAL');
                    _load();
                  },
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('Packaging'),
                  selected: _filterType == 'PACKAGING_MATERIAL',
                  onSelected: (_) {
                    setState(() => _filterType = 'PACKAGING_MATERIAL');
                    _load();
                  },
                ),
              ],
            ),
          ),
          if (!_isLoading && _error == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                '${_products.length} product${_products.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: 6,
        itemBuilder: (_, _) => Card(
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: ListTile(
              leading: const CircleAvatar(child: SizedBox()),
              title: Container(height: 14, color: Colors.white),
              subtitle: Container(height: 12, color: Colors.white),
            ),
          ),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(_error!),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, size: 100, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No products', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text('Tap + to add your first product'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _products.length,
        itemBuilder: (context, i) => _buildProductCard(_products[i]),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> p) {
    final type =
        p['categoryType'] as String? ?? p['type'] as String? ?? 'UNKNOWN';
    final color = _typeColor(type);
    final isAdmin = ref.read(authNotifierProvider).user?.isAdmin ?? false;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(
            type == 'FINISHED_GOOD'
                ? Icons.local_drink
                : type == 'RAW_MATERIAL'
                ? Icons.science
                : type == 'PACKAGING_MATERIAL'
                ? Icons.inventory
                : Icons.help_outline,
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          p['name'] as String,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SKU: ${p['sku']}', style: const TextStyle(fontSize: 11)),
            const SizedBox(height: 2),
            Row(
              children: [
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
                    type.replaceAll('_', ' '),
                    style: TextStyle(
                      fontSize: 9,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'UoM: ${p['unitOfMeasure'] ?? '—'}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (p['isActive'] == false)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'INACTIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (isAdmin)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (v) {
                  if (v == 'edit') {
                    context.push('/products/${p['id']}/edit');
                  } else if (v == 'delete') {
                    _deleteProduct(p);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
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
                ],
              ),
          ],
        ),
      ),
    );
  }
}
