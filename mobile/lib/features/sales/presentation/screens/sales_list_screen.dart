import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:artemis_business_os/core/providers.dart';
import 'package:artemis_business_os/core/theme/app_theme.dart';

class SalesListScreen extends ConsumerStatefulWidget {
  const SalesListScreen({super.key});

  @override
  ConsumerState<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends ConsumerState<SalesListScreen> {
  List<dynamic> _sales = [];
  bool _isLoading = true;
  String _filter = 'ALL';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
      final res = await api.get('/sales');
      setState(() {
        _sales = res.data as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredSales = _sales.where((s) {
      final sale = s as Map<String, dynamic>;
      if (_filter != 'ALL' && sale['orderType'] != _filter) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final orderNumber = (sale['orderNumber'] as String? ?? '').toLowerCase();
      final customerName = (sale['customerName'] as String? ?? '')
          .toLowerCase();
      return orderNumber.contains(q) || customerName.contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadSales),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/sales/create'),
        icon: const Icon(Icons.add),
        label: const Text('New Sale'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by order # or customer...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  value: 'ALL',
                  current: _filter,
                  onTap: (v) => setState(() => _filter = v),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Cash',
                  value: 'CASH_SALE',
                  current: _filter,
                  onTap: (v) => setState(() => _filter = v),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Credit',
                  value: 'CREDIT_SALE',
                  current: _filter,
                  onTap: (v) => setState(() => _filter = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadSales,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: filteredSales.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            child: Text(
                              '${filteredSales.length} sale${filteredSales.length == 1 ? '' : 's'}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        }
                        final sale =
                            filteredSales[index - 1] as Map<String, dynamic>;
                        final isPaid = sale['paymentStatus'] == 'PAID';
                        final isCancelled = sale['isCancelled'] == true;
                        final isCash = sale['orderType'] == 'CASH_SALE';
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isCancelled
                                  ? Colors.grey.shade200
                                  : isPaid
                                  ? Colors.green.shade100
                                  : (isCash
                                        ? Colors.blue.shade100
                                        : Colors.orange.shade100),
                              child: Icon(
                                isCancelled
                                    ? Icons.block
                                    : isPaid
                                    ? Icons.check_circle
                                    : (isCash
                                          ? Icons.payments
                                          : Icons.credit_card),
                                color: isCancelled
                                    ? Colors.grey
                                    : isPaid
                                    ? Colors.green
                                    : (isCash ? Colors.blue : Colors.orange),
                              ),
                            ),
                            title: Text(
                              sale['orderNumber'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sale['customerName'] as String? ?? 'Unknown',
                                ),
                                Text(
                                  DateFormat('MMM dd, yyyy • HH:mm').format(
                                    DateTime.parse(
                                      sale['orderDate'] as String,
                                    ).toLocal(),
                                  ),
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'ETB ${(sale['totalAmount'] as num).toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isCancelled
                                        ? Colors.grey
                                        : isPaid
                                        ? Colors.green
                                        : Colors.orange,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isCancelled
                                        ? 'CANCELLED'
                                        : isPaid
                                        ? 'PAID'
                                        : 'PENDING',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
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
