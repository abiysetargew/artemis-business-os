import 'package:artemis_business_os/core/network/api_errors.dart';
import 'package:artemis_business_os/core/providers.dart';
import 'package:artemis_business_os/core/theme/app_theme.dart';
import 'package:artemis_business_os/core/widgets/data_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class CreateSalesOrderScreen extends ConsumerStatefulWidget {
  const CreateSalesOrderScreen({super.key});

  @override
  ConsumerState<CreateSalesOrderScreen> createState() =>
      _CreateSalesOrderScreenState();
}

class _CreateSalesOrderScreenState
    extends ConsumerState<CreateSalesOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();

  List<dynamic> _customers = [];
  List<dynamic> _products = [];
  List<dynamic> _filteredProducts = [];
  List<String> _regions = [];
  final Map<String, List<String>> _regionCities = {};
  final Map<String, dynamic> _inventoryByProduct = {};

  Map<String, dynamic>? _selectedCustomer;
  String? _selectedRegion;
  String? _selectedCity;
  String _orderType = 'CASH_SALE';
  String _search = '';
  bool _isLoading = true;
  bool _isSaving = false;

  final Map<String, TextEditingController> _qtyControllers = {};
  final Map<String, TextEditingController> _priceControllers = {};

  @override
  void initState() {
    super.initState();
    _loadAll();
    _searchController.addListener(() {
      setState(() => _search = _searchController.text);
      _filterProducts();
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _searchController.dispose();
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    for (final c in _priceControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final results = await Future.wait([
        api.get('/customers'),
        api.get('/products', queryParameters: {'type': 'FINISHED_GOOD'}),
        api.get('/locations/regions'),
        api.get('/locations/regions-cities'),
        api.get('/inventory'),
      ]);
      final regions = (results[2].data as List<dynamic>).cast<String>();
      final citiesMap = (results[3].data as Map<String, dynamic>);
      final inventory = results[4].data as List<dynamic>;

      final invByProduct = <String, dynamic>{};
      for (final inv in inventory) {
        final m = inv as Map<String, dynamic>;
        invByProduct[m['productId'] as String] = m;
      }

      setState(() {
        _customers = results[0].data as List<dynamic>;
        _products = results[1].data as List<dynamic>;
        _regions = regions;
        _regionCities
          ..clear()
          ..addAll(
            citiesMap.map(
              (k, v) => MapEntry(k, (v as List<dynamic>).cast<String>()),
            ),
          );
        _inventoryByProduct
          ..clear()
          ..addAll(invByProduct);
        _filteredProducts = List.from(_products);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${parseApiError(e)}'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  void _filterProducts() {
    if (_search.isEmpty) {
      setState(() => _filteredProducts = List.from(_products));
      return;
    }
    final q = _search.toLowerCase();
    setState(() {
      _filteredProducts = _products.where((p) {
        final m = p as Map<String, dynamic>;
        return (m['name'] as String).toLowerCase().contains(q) ||
            (m['sku'] as String).toLowerCase().contains(q);
      }).toList();
    });
  }

  double get _total {
    double total = 0;
    for (final productId in _qtyControllers.keys) {
      final qty = double.tryParse(_qtyControllers[productId]!.text) ?? 0;
      final price = double.tryParse(_priceControllers[productId]!.text) ?? 0;
      total += qty * price;
    }
    return total;
  }

  int get _itemCount => _qtyControllers.values
      .where((c) => (double.tryParse(c.text) ?? 0) > 0)
      .length;

  void _toggleProduct(Map<String, dynamic> product) {
    final id = product['id'] as String;
    final isAdded = _qtyControllers.containsKey(id);
    setState(() {
      if (!isAdded) {
        _qtyControllers[id] = TextEditingController(text: '1');
        _priceControllers[id] = TextEditingController();
      } else {
        _qtyControllers[id]!.dispose();
        _priceControllers[id]!.dispose();
        _qtyControllers.remove(id);
        _priceControllers.remove(id);
      }
    });
  }

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null) {
      _showError('Please select a customer');
      return;
    }
    if (_selectedRegion == null) {
      _showError('Please select a region');
      return;
    }
    if (_selectedCity == null) {
      _showError('Please select a city');
      return;
    }

    final items = <Map<String, dynamic>>[];
    for (final productId in _qtyControllers.keys) {
      final qty = double.tryParse(_qtyControllers[productId]!.text) ?? 0;
      final price = double.tryParse(_priceControllers[productId]!.text) ?? 0;
      if (qty > 0 && price > 0) {
        items.add({
          'productId': productId,
          'quantity': qty,
          'unitPrice': price,
        });
      }
    }

    if (items.isEmpty) {
      _showError('Please add at least one product with quantity and price');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post(
        '/sales',
        data: {
          'customerId': _selectedCustomer!['id'],
          'orderType': _orderType,
          'region': _selectedRegion,
          'city': _selectedCity,
          'notes': _notesController.text,
          'items': items,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Order ${response.data['orderNumber']} created successfully!',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) _showError(parseApiError(e));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.dangerColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('New Sale')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Sale'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  _buildOrderTypeCard(),
                  const SizedBox(height: 16),
                  _buildCustomerSection(),
                  const SizedBox(height: 20),
                  _buildProductsSection(),
                  if (_qtyControllers.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildItemsSection(),
                  ],
                  const SizedBox(height: 20),
                  _buildLocationSection(),
                  const SizedBox(height: 20),
                  _buildNotesSection(),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTypeCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.slate200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: AppTheme.primaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Type',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.slate900,
                      ),
                    ),
                    Text(
                      'How is this order being paid?',
                      style: TextStyle(fontSize: 12, color: AppTheme.slate500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _OrderTypeOption(
                  selected: _orderType == 'CASH_SALE',
                  icon: Icons.payments,
                  label: 'Cash Sale',
                  description: 'Paid immediately',
                  color: AppTheme.successColor,
                  onTap: () => setState(() => _orderType = 'CASH_SALE'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OrderTypeOption(
                  selected: _orderType == 'CREDIT_SALE',
                  icon: Icons.credit_card,
                  label: 'Credit Sale',
                  description: 'Add to balance',
                  color: AppTheme.warningColor,
                  onTap: () => setState(() => _orderType = 'CREDIT_SALE'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Customer',
          subtitle: 'Select who you are selling to',
        ),
        DropdownButtonFormField<Map<String, dynamic>>(
          initialValue: _selectedCustomer,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Customer *',
            prefixIcon: Icon(Icons.person_outline),
          ),
          items: _customers.map<DropdownMenuItem<Map<String, dynamic>>>((c) {
            final m = c as Map<String, dynamic>;
            final balance = (m['outstandingBalance'] as num?) ?? 0;
            final name = m['name'] as String? ?? 'Unknown';
            return DropdownMenuItem(
              value: m,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: balance > 0
                        ? AppTheme.warningLight
                        : AppTheme.successLight,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: balance > 0
                            ? AppTheme.warningColor
                            : AppTheme.successColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          balance > 0
                              ? 'Owes: ETB ${NumberFormat.decimalPattern().format(balance)}'
                              : 'No outstanding balance',
                          style: TextStyle(
                            fontSize: 11,
                            color: balance > 0
                                ? AppTheme.warningColor
                                : AppTheme.successColor,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (c) => setState(() => _selectedCustomer = c),
          validator: (v) => v == null ? 'Customer is required' : null,
        ),
      ],
    );
  }

  Widget _buildProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Products',
          subtitle: 'Tap to add to cart',
          action: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _qtyControllers.isEmpty
                  ? AppTheme.slate100
                  : AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Text(
              '${_qtyControllers.length} selected',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _qtyControllers.isEmpty
                    ? AppTheme.slate500
                    : AppTheme.primaryColor,
              ),
            ),
          ),
        ),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search products by name or SKU...',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _search.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
        const SizedBox(height: 12),
        if (_filteredProducts.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.slate50,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.slate200),
            ),
            child: const Center(
              child: Text(
                'No products match your search',
                style: TextStyle(color: AppTheme.slate500, fontSize: 13),
              ),
            ),
          )
        else
          ..._filteredProducts.map((p) {
            final m = p as Map<String, dynamic>;
            final id = m['id'] as String;
            final isAdded = _qtyControllers.containsKey(id);
            final inv = _inventoryByProduct[id] as Map<String, dynamic>?;
            final stock = inv != null
                ? (inv['availableQuantity'] as num?) ?? 0
                : 0;
            final lowStock = stock > 0 && stock < 10;
            final outOfStock = stock <= 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: outOfStock ? null : () => _toggleProduct(m),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isAdded
                        ? AppTheme.primaryLight
                        : AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: isAdded
                          ? AppTheme.primaryColor
                          : AppTheme.slate200,
                      width: isAdded ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isAdded
                              ? AppTheme.primaryColor
                              : AppTheme.slate100,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSm,
                          ),
                        ),
                        child: Icon(
                          isAdded ? Icons.check : Icons.inventory_2_outlined,
                          color: isAdded ? Colors.white : AppTheme.slate500,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m['name'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: outOfStock
                                    ? AppTheme.slate400
                                    : AppTheme.slate900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  m['sku'] as String,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.slate500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (inv != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: outOfStock
                                          ? AppTheme.dangerLight
                                          : lowStock
                                          ? AppTheme.warningLight
                                          : AppTheme.successLight,
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusSm,
                                      ),
                                    ),
                                    child: Text(
                                      'Stock: ${stock.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: outOfStock
                                            ? AppTheme.dangerColor
                                            : lowStock
                                            ? AppTheme.warningColor
                                            : AppTheme.successColor,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isAdded)
                        const Icon(
                          Icons.check_circle,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildItemsSection() {
    final entries = _qtyControllers.keys.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Order Items',
          subtitle: 'Set quantity and price',
          action: TextButton.icon(
            onPressed: () {
              setState(() {
                for (final id in List<String>.from(_qtyControllers.keys)) {
                  _qtyControllers[id]!.dispose();
                  _priceControllers[id]!.dispose();
                  _qtyControllers.remove(id);
                  _priceControllers.remove(id);
                }
              });
            },
            icon: const Icon(Icons.delete_sweep, size: 18),
            label: const Text('Clear all'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerColor),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.slate200),
          ),
          child: Column(
            children: List.generate(entries.length, (i) {
              final productId = entries[i];
              final product =
                  _products.firstWhere(
                        (p) => (p as Map<String, dynamic>)['id'] == productId,
                      )
                      as Map<String, dynamic>;
              final qtyCtrl = _qtyControllers[productId]!;
              final priceCtrl = _priceControllers[productId]!;

              final qty = double.tryParse(qtyCtrl.text) ?? 0;
              final price = double.tryParse(priceCtrl.text) ?? 0;
              final lineTotal = qty * price;

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: i < entries.length - 1
                        ? const BorderSide(color: AppTheme.slate200)
                        : BorderSide.none,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product['name'] as String,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.slate900,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 18,
                            color: AppTheme.dangerColor,
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            setState(() {
                              qtyCtrl.dispose();
                              priceCtrl.dispose();
                              _qtyControllers.remove(productId);
                              _priceControllers.remove(productId);
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: qtyCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}'),
                              ),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Qty',
                              isDense: true,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: priceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}'),
                              ),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Unit Price (ETB)',
                              prefixText: 'ETB ',
                              isDense: true,
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Required';
                              }
                              final p = double.tryParse(v);
                              if (p == null || p <= 0) return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 90,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.centerRight,
                          child: Text(
                            'ETB ${NumberFormat.decimalPattern().format(lineTotal)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Delivery Location',
          subtitle: 'Where is this order going?',
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.slate200),
          ),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedRegion,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Region *',
                  prefixIcon: Icon(Icons.map_outlined),
                ),
                items: _regions
                    .map<DropdownMenuItem<String>>(
                      (r) => DropdownMenuItem(value: r, child: Text(r)),
                    )
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedRegion = v;
                    _selectedCity = null;
                  });
                },
                validator: (v) => v == null ? 'Region is required' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _selectedCity,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'City *',
                  prefixIcon: const Icon(Icons.location_city_outlined),
                  hintText: _selectedRegion == null
                      ? 'Select region first'
                      : 'Choose a city',
                ),
                items: _selectedRegion == null
                    ? const <DropdownMenuItem<String>>[]
                    : (_regionCities[_selectedRegion] ?? [])
                          .map<DropdownMenuItem<String>>(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                onChanged: _selectedRegion == null
                    ? null
                    : (v) => setState(() => _selectedCity = v),
                validator: (v) => v == null ? 'City is required' : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Notes',
          subtitle: 'Optional remarks for this order',
        ),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'e.g. Special handling, delivery instructions...',
            prefixIcon: Padding(
              padding: EdgeInsets.only(bottom: 60),
              child: Icon(Icons.note_outlined),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final hasItems = _itemCount > 0;
    final canSave =
        !_isSaving && hasItems && _selectedCustomer != null && _total > 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        '$_itemCount item${_itemCount == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.slate500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _orderType == 'CASH_SALE'
                              ? AppTheme.successLight
                              : AppTheme.warningLight,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusFull,
                          ),
                        ),
                        child: Text(
                          _orderType == 'CASH_SALE' ? 'CASH' : 'CREDIT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _orderType == 'CASH_SALE'
                                ? AppTheme.successColor
                                : AppTheme.warningColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ETB ${NumberFormat.decimalPattern().format(_total)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.slate900,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: canSave ? _saveOrder : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.check_circle_outline, size: 20),
                label: const Text(
                  'Save Order',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderTypeOption extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _OrderTypeOption({
    required this.selected,
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : AppTheme.slate50,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: selected ? color : AppTheme.slate200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: selected ? color : AppTheme.slate500,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: selected ? color : AppTheme.slate900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: selected ? color : AppTheme.slate500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
