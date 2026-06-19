import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:artemis_business_os/core/providers.dart';
import 'package:artemis_business_os/core/theme/app_theme.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  List<dynamic> _allCustomers = [];
  List<dynamic> _filteredCustomers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filter = 'ALL'; // ALL, WITH_BALANCE, ACTIVE
  String _sortBy = 'NAME'; // NAME, BALANCE, BALANCE_DESC

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/customers');
      setState(() {
        _allCustomers = response.data as List<dynamic>;
        _isLoading = false;
        _applyFilters();
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    var filtered = List<dynamic>.from(_allCustomers);

    // Search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((c) {
        return (c['name'] as String).toLowerCase().contains(query) ||
            (c['phoneNumber'] as String).toLowerCase().contains(query) ||
            (c['city'] as String).toLowerCase().contains(query);
      }).toList();
    }

    // Filter
    if (_filter == 'WITH_BALANCE') {
      filtered = filtered
          .where((c) => (c['outstandingBalance'] as num) > 0)
          .toList();
    } else if (_filter == 'ACTIVE') {
      filtered = filtered.where((c) => c['accountStatus'] == 'ACTIVE').toList();
    }

    // Sort
    if (_sortBy == 'NAME') {
      filtered.sort(
        (a, b) => (a['name'] as String).compareTo(b['name'] as String),
      );
    } else if (_sortBy == 'BALANCE_DESC') {
      filtered.sort(
        (a, b) => (b['outstandingBalance'] as num).compareTo(
          a['outstandingBalance'] as num,
        ),
      );
    }

    setState(() {
      _filteredCustomers = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCustomers,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await context.push<bool>('/customers/create');
          if (created == true) {
            _loadCustomers();
          }
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add Customer'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, phone, or city...',
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
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _applyFilters();
              },
            ),
          ),
          // Filter chips
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'All',
                  value: 'ALL',
                  current: _filter,
                  onTap: (v) {
                    setState(() => _filter = v);
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'With Balance',
                  value: 'WITH_BALANCE',
                  current: _filter,
                  onTap: (v) {
                    setState(() => _filter = v);
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Active',
                  value: 'ACTIVE',
                  current: _filter,
                  onTap: (v) {
                    setState(() => _filter = v);
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 8),
                _SortChip(
                  label: 'Sort: Name',
                  value: 'NAME',
                  current: _sortBy,
                  onTap: (v) {
                    setState(() => _sortBy = v);
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 8),
                _SortChip(
                  label: 'Sort: Highest Debt',
                  value: 'BALANCE_DESC',
                  current: _sortBy,
                  onTap: (v) {
                    setState(() => _sortBy = v);
                    _applyFilters();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Results count
          if (!_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              width: double.infinity,
              child: Text(
                '${_filteredCustomers.length} customer${_filteredCustomers.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          // List
          Expanded(
            child: _isLoading
                ? _buildShimmerLoading()
                : _filteredCustomers.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadCustomers,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final customer =
                            _filteredCustomers[index] as Map<String, dynamic>;
                        return _buildCustomerCard(customer);
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
      itemCount: 5,
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
          Icon(Icons.people_outline, size: 100, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'No customers found' : 'No customers yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search or filters'
                : 'Tap + to add your first customer',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> customer) {
    final balance = customer['outstandingBalance'] as num;
    final hasBalance = balance > 0;

    return Card(
      child: InkWell(
        onTap: () {
          context.push('/customers/${customer['id']}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: hasBalance
                    ? Colors.red.shade100
                    : Colors.green.shade100,
                child: Text(
                  (customer['name'] as String).substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: hasBalance ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer['name'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${customer['city']} • ${customer['phoneNumber']}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: customer['accountStatus'] == 'ACTIVE'
                                ? Colors.green.shade50
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            customer['accountStatus'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              color: customer['accountStatus'] == 'ACTIVE'
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Credit: ETB ${(customer['creditLimit'] as num).toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    hasBalance ? 'OWES' : 'CLEAR',
                    style: TextStyle(
                      fontSize: 10,
                      color: hasBalance ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'ETB ${balance.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: hasBalance ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

class _SortChip extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final Function(String) onTap;

  const _SortChip({
    required this.label,
    required this.value,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = current == value;
    return Chip(
      label: Text(label),
      backgroundColor: isActive ? AppTheme.primaryColor : null,
      labelStyle: TextStyle(
        color: isActive ? Colors.white : null,
        fontSize: 12,
      ),
      deleteIcon: const Icon(Icons.swap_vert, size: 16),
      onDeleted: () => onTap(value),
    );
  }
}
