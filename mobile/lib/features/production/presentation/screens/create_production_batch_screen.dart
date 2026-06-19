import 'package:artemis_business_os/core/network/api_errors.dart';
import 'package:artemis_business_os/core/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CreateProductionBatchScreen extends ConsumerStatefulWidget {
  const CreateProductionBatchScreen({super.key});

  @override
  ConsumerState<CreateProductionBatchScreen> createState() =>
      _CreateProductionBatchScreenState();
}

class _CreateProductionBatchScreenState
    extends ConsumerState<CreateProductionBatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _batchNumberController = TextEditingController();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();

  List<dynamic> _finishedGoods = [];
  Map<String, dynamic>? _selectedProduct;
  Map<String, dynamic>? _selectedBom;
  bool _isLoadingProducts = false;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadFinishedGoods();
  }

  @override
  void dispose() {
    _batchNumberController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadFinishedGoods() async {
    setState(() => _isLoadingProducts = true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get(
        '/products',
        queryParameters: {'type': 'FINISHED_GOOD'},
      );
      setState(() {
        _finishedGoods = res.data as List<dynamic>;
        _isLoadingProducts = false;
      });
    } catch (e) {
      setState(() => _isLoadingProducts = false);
    }
  }

  Future<void> _loadBom(String productId) async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('/production/boms/product/$productId/active');
      setState(() => _selectedBom = res.data);
    } catch (e) {
      setState(() => _selectedBom = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active BOM found for this product')),
        );
      }
    }
  }

  Future<void> _createBatch() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a product')));
      return;
    }

    setState(() => _isCreating = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post(
        '/production/batches',
        data: {
          'finishedProductId': _selectedProduct!['id'],
          'batchNumber': _batchNumberController.text,
          'quantityProduced': double.parse(_quantityController.text),
          'notes': _notesController.text,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Batch ${response.data['batchNumber']} created successfully!',
            ),
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
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Production Batch'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoadingProducts
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Product Selection
                  Text(
                    'Finished Product',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Map<String, dynamic>>(
                    initialValue: _selectedProduct,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Select Product to Produce',
                      prefixIcon: Icon(Icons.factory),
                    ),
                    items: _finishedGoods
                        .map<DropdownMenuItem<Map<String, dynamic>>>((p) {
                          return DropdownMenuItem(
                            value: p as Map<String, dynamic>,
                            child: Text(
                              p['name'] as String,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        })
                        .toList(),
                    onChanged: (p) {
                      setState(() {
                        _selectedProduct = p;
                        _selectedBom = null;
                      });
                      if (p != null) {
                        _loadBom(p['id'] as String);
                      }
                    },
                    validator: (v) =>
                        v == null ? 'Please select a product' : null,
                  ),
                  const SizedBox(height: 16),

                  // BOM Display
                  if (_selectedBom != null) ...[
                    Text(
                      'Bill of Materials (BOM)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Card(
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.science, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Version: ${_selectedBom!['bomVersion']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...((_selectedBom!['items'] as List?) ?? []).map<
                              Widget
                            >((item) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                                child: Text(
                                  '• ${item['materialName']}: ${item['quantity']} ${item['unitOfMeasure']}',
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Batch Number
                  Text(
                    'Batch Details',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _batchNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Batch Number (Optional)',
                      prefixIcon: Icon(Icons.tag),
                      hintText: 'Leave blank for auto-generation',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quantity
                  TextFormField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Quantity to Produce',
                      prefixIcon: Icon(Icons.numbers),
                      hintText: 'e.g., 500',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Please enter quantity';
                      }
                      final qty = double.tryParse(v);
                      if (qty == null || qty <= 0) {
                        return 'Enter valid quantity';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // Info Card
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'The system will automatically:\n• Check material availability\n• Deduct raw materials\n• Add finished goods to inventory',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Create Button
                  ElevatedButton.icon(
                    onPressed: _isCreating ? null : _createBatch,
                    icon: _isCreating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.play_arrow),
                    label: const Text('START PRODUCTION'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
