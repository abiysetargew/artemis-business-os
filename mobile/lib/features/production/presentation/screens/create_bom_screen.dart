import 'package:artemis_business_os/core/network/api_errors.dart';
import 'package:artemis_business_os/core/providers.dart';
import 'package:artemis_business_os/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class CreateBomScreen extends ConsumerStatefulWidget {
  final String? existingBomId;

  const CreateBomScreen({super.key, this.existingBomId});

  @override
  ConsumerState<CreateBomScreen> createState() => _CreateBomScreenState();
}

class _CreateBomScreenState extends ConsumerState<CreateBomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _versionController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _effectiveDate = DateTime.now();
  bool _isActive = true;

  List<dynamic> _finishedGoods = [];
  List<dynamic> _rawMaterials = [];
  Map<String, dynamic>? _selectedProduct;
  final List<_BomLine> _lines = [];
  bool _isLoadingProducts = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    if (widget.existingBomId != null) {
      _versionController.text = '1';
    }
  }

  @override
  void dispose() {
    _versionController.dispose();
    _notesController.dispose();
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final results = await Future.wait<dynamic>([
        api.get('/products', queryParameters: {'type': 'FINISHED_GOOD'}),
        api.get('/products', queryParameters: {'type': 'RAW_MATERIAL'}),
      ]);
      setState(() {
        _finishedGoods = results[0].data as List<dynamic>;
        _rawMaterials = results[1].data as List<dynamic>;
        _isLoadingProducts = false;
      });
    } catch (e) {
      setState(() {
        _error = parseApiError(e);
        _isLoadingProducts = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a finished product')),
      );
      return;
    }
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one material')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiClientProvider);
      final items = _lines
          .map(
            (l) => {
              'materialProductId': l.material!['id'] as String,
              'quantity': double.parse(l.quantityController.text),
            },
          )
          .toList();
      await api.post(
        '/production/boms',
        data: {
          'finishedProductId': _selectedProduct!['id'],
          'version': _versionController.text.trim(),
          'effectiveDate': _effectiveDate.toIso8601String(),
          'notes': _notesController.text.trim(),
          'isActive': _isActive,
          'items': items,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('BOM created'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(true);
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

  void _addLine() {
    if (_rawMaterials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No raw materials available. Create some in Products first.',
          ),
        ),
      );
      return;
    }
    setState(() {
      _lines.add(
        _BomLine(
          onRemove: () => setState(() {
            _lines.removeWhere((l) => l.key == _lines.last.key);
          }),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProducts) {
      return Scaffold(
        appBar: AppBar(title: const Text('New BOM')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null && _finishedGoods.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('New BOM')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
              const SizedBox(height: 12),
              Text(_error!),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _loadProducts,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('New BOM'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Product selector
            Text(
              'Finished Product',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Map<String, dynamic>>(
              initialValue: _selectedProduct,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Select finished good *',
                prefixIcon: Icon(Icons.local_drink),
              ),
              items: _finishedGoods.map<DropdownMenuItem<Map<String, dynamic>>>(
                (p) {
                  return DropdownMenuItem(
                    value: p as Map<String, dynamic>,
                    child: Text(
                      '${p['name']} (${p['sku']})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ).toList(),
              onChanged: (p) => setState(() => _selectedProduct = p),
              validator: (v) => v == null ? 'Please select a product' : null,
            ),
            const SizedBox(height: 16),
            // Version
            TextFormField(
              controller: _versionController,
              decoration: const InputDecoration(
                labelText: 'Version *',
                prefixIcon: Icon(Icons.numbers),
                hintText: 'e.g., 1, 1.0, 2026-Q1',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Version is required' : null,
            ),
            const SizedBox(height: 16),
            // Effective date
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Effective Date'),
                subtitle: Text(
                  DateFormat('MMM dd, yyyy').format(_effectiveDate),
                ),
                trailing: const Icon(Icons.edit),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _effectiveDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => _effectiveDate = picked);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            // Active switch
            SwitchListTile(
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              title: const Text('Active'),
              subtitle: const Text(
                'Only one BOM can be active per product. Activating will deactivate the prior version.',
              ),
              secondary: Icon(
                _isActive ? Icons.check_circle : Icons.pause_circle,
                color: _isActive ? AppTheme.successColor : Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            // Materials section
            Row(
              children: [
                Text(
                  'Materials',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addLine,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Material'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (_lines.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.science,
                          size: 50,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 8),
                        const Text('No materials added yet'),
                        const SizedBox(height: 4),
                        const Text(
                          'Tap "Add Material" above to build the recipe',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ..._lines.asMap().entries.map(
                (e) => _buildLineCard(e.key, e.value, _rawMaterials),
              ),
            const SizedBox(height: 24),
            // Submit
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
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
              label: const Text('CREATE BOM'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
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

  Widget _buildLineCard(int index, _BomLine line, List<dynamic> materials) {
    return Card(
      key: line.key,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.orange.shade100,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    line.material == null
                        ? 'Material #${index + 1}'
                        : (line.material!['name'] as String),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: line.onRemove,
                ),
              ],
            ),
            DropdownButtonFormField<Map<String, dynamic>>(
              initialValue: line.material,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Material *',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: materials.map<DropdownMenuItem<Map<String, dynamic>>>((m) {
                return DropdownMenuItem(
                  value: m as Map<String, dynamic>,
                  child: Text(
                    '${m['name']} (${m['sku']})',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (m) => setState(() => line.material = m),
              validator: (v) => v == null ? 'Pick a material' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: line.quantityController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,4}')),
              ],
              decoration: InputDecoration(
                labelText:
                    'Quantity per unit (${(line.material?['unitOfMeasure'] as String?) ?? 'units'}) *',
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                final n = double.tryParse(v);
                if (n == null || n <= 0) return 'Must be > 0';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BomLine {
  final GlobalKey key = GlobalKey();
  Map<String, dynamic>? material;
  final TextEditingController quantityController = TextEditingController(
    text: '1',
  );
  final VoidCallback onRemove;

  _BomLine({required this.onRemove});

  void dispose() {
    quantityController.dispose();
  }
}
