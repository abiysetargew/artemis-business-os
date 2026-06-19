import 'package:artemis_business_os/core/network/api_errors.dart';
import 'package:artemis_business_os/core/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  List<dynamic> _customers = [];
  List<dynamic> _products = [];
  Map<String, dynamic>? _selectedCustomer;
  final Map<String, TextEditingController> _qtyControllers = {};
  final Map<String, TextEditingController> _priceControllers = {};
  String _orderType = 'CASH_SALE';
  String _region = '';
  String _city = '';
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    for (final c in _priceControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final customersRes = await api.get('/customers');
      final productsRes = await api.get(
        '/products',
        queryParameters: {'type': 'FINISHED_GOOD'},
      );
      setState(() {
        _customers = customersRes.data as List<dynamic>;
        _products = productsRes.data as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${parseApiError(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a customer')));
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product')),
      );
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
          'region': _region,
          'city': _city,
          'notes': _notesController.text,
          'items': items,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order ${response.data['orderNumber']} created!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(parseApiError(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Order Type
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.payment, size: 20),
                          const SizedBox(width: 12),
                          const Text(
                            'Order Type:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                  value: 'CASH_SALE',
                                  label: Text('Cash'),
                                  icon: Icon(Icons.payments),
                                ),
                                ButtonSegment(
                                  value: 'CREDIT_SALE',
                                  label: Text('Credit'),
                                  icon: Icon(Icons.credit_card),
                                ),
                              ],
                              selected: {_orderType},
                              onSelectionChanged: (s) =>
                                  setState(() => _orderType = s.first),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Customer Selection
                  Text(
                    'Customer',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Map<String, dynamic>>(
                    initialValue: _selectedCustomer,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Select Customer',
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: _customers.map<DropdownMenuItem<Map<String, dynamic>>>((
                      c,
                    ) {
                      return DropdownMenuItem(
                        value: c as Map<String, dynamic>,
                        child: Text(
                          '${c['name']} • ETB ${(c['outstandingBalance'] as num).toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (c) => setState(() => _selectedCustomer = c),
                    validator: (v) =>
                        v == null ? 'Please select a customer' : null,
                  ),
                  const SizedBox(height: 16),

                  // Products
                  Text(
                    'Products',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (_products.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _products.map<Widget>((p) {
                        final id = p['id'] as String;
                        final isAdded = _qtyControllers.containsKey(id);
                        return ActionChip(
                          label: Text(p['name'] as String),
                          avatar: Icon(
                            isAdded ? Icons.check : Icons.add,
                            size: 18,
                          ),
                          backgroundColor: isAdded
                              ? Colors.green.shade100
                              : null,
                          onPressed: () {
                            setState(() {
                              if (!isAdded) {
                                _qtyControllers[id] = TextEditingController(
                                  text: '1',
                                );
                                _priceControllers[id] = TextEditingController(
                                  text: '',
                                );
                              } else {
                                _qtyControllers[id]!.dispose();
                                _priceControllers[id]!.dispose();
                                _qtyControllers.remove(id);
                                _priceControllers.remove(id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 16),

                  // Added Products
                  if (_qtyControllers.isNotEmpty) ...[
                    Text(
                      'Items',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ..._qtyControllers.keys.map((productId) {
                      final product = _products.firstWhere(
                        (p) => p['id'] == productId,
                      );
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      product['name'] as String,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => setState(() {
                                      _qtyControllers[productId]!.dispose();
                                      _priceControllers[productId]!.dispose();
                                      _qtyControllers.remove(productId);
                                      _priceControllers.remove(productId);
                                    }),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _qtyControllers[productId],
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Quantity',
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _priceControllers[productId],
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Unit Price',
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  // Region & City
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: _region,
                          decoration: const InputDecoration(
                            labelText: 'Region *',
                            prefixIcon: Icon(Icons.map),
                          ),
                          onChanged: (v) => _region = v,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: _city,
                          decoration: const InputDecoration(
                            labelText: 'City *',
                            prefixIcon: Icon(Icons.location_city),
                          ),
                          onChanged: (v) => _city = v,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom Bar with Total and Save
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Total Amount',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            'ETB ${_total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveOrder,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check),
                        label: const Text('SAVE ORDER'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
