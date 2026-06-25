import 'package:artemis_business_os/core/network/api_errors.dart';
import 'package:artemis_business_os/core/providers.dart';
import 'package:artemis_business_os/core/theme/app_theme.dart';
import 'package:artemis_business_os/core/widgets/confirm_dialog.dart';
import 'package:artemis_business_os/core/widgets/data_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EditProductScreen extends ConsumerStatefulWidget {
  final String productId;

  const EditProductScreen({super.key, required this.productId});

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _unitController = TextEditingController();
  final _reorderController = TextEditingController(text: '0');

  List<dynamic> _categories = [];
  Map<String, dynamic>? _selectedCategory;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  bool _isActive = true;
  Map<String, dynamic>? _inventoryItem;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _descriptionController.dispose();
    _unitController.dispose();
    _reorderController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final results = await Future.wait<dynamic>([
        api.get('/products/${widget.productId}'),
        api.get('/products/categories'),
        api.get('/inventory'),
      ]);
      final p = results[0].data as Map<String, dynamic>;
      _nameController.text = p['name'] as String? ?? '';
      _skuController.text = p['sku'] as String? ?? '';
      _descriptionController.text = p['description'] as String? ?? '';
      _unitController.text = p['unitOfMeasure'] as String? ?? '';
      _reorderController.text =
          (p['reorderPoint'] as num?)?.toStringAsFixed(0) ?? '0';
      _isActive = p['isActive'] as bool? ?? true;
      final inventory = (results[2].data as List<dynamic>);
      Map<String, dynamic>? invItem;
      for (final item in inventory) {
        if ((item as Map<String, dynamic>)['productId'] == widget.productId) {
          invItem = item;
          break;
        }
      }
      setState(() {
        _categories = results[1].data as List<dynamic>;
        _isLoading = false;
        _selectedCategory = _categories.firstWhere(
          (c) => (c as Map<String, dynamic>)['id'] == p['categoryId'],
          orElse: () => _categories.isNotEmpty
              ? _categories.first as Map<String, dynamic>
              : null,
        );
        _inventoryItem = invItem;
      });
    } catch (e) {
      setState(() {
        _error = parseApiError(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      showAppSnackBar(
        context,
        message: 'Please select a category',
        isError: true,
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.patch(
        '/products/${widget.productId}',
        data: {
          'name': _nameController.text.trim(),
          'sku': _skuController.text.trim().toUpperCase(),
          'description': _descriptionController.text.trim(),
          'unitOfMeasure': _unitController.text.trim(),
          'reorderPoint': double.tryParse(_reorderController.text) ?? 0,
          'categoryId': _selectedCategory!['id'],
          'isActive': _isActive,
        },
      );
      if (mounted) {
        showAppSnackBar(context, message: 'Product updated', isSuccess: true);
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, message: parseApiError(e), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _createInitialStock() async {
    final qtyController = TextEditingController();
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Initial Stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'How many units do you currently have on hand?',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qtyController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Initial quantity'),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final q = double.tryParse(qtyController.text);
              if (q != null && q >= 0) Navigator.pop(ctx, q);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    qtyController.dispose();
    if (result == null) return;

    try {
      final api = ref.read(apiClientProvider);
      await api.post(
        '/inventory',
        data: {'productId': widget.productId, 'initialQuantity': result},
      );
      if (mounted) {
        showAppSnackBar(
          context,
          message: 'Initial stock set to ${result.toStringAsFixed(0)}',
          isSuccess: true,
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, message: parseApiError(e), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Product')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Product')),
        body: Center(
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
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (!_isSaving)
            TextButton(
              onPressed: _save,
              child: const Text(
                'SAVE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Product Name *',
                prefixIcon: Icon(Icons.label),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _skuController,
              decoration: const InputDecoration(
                labelText: 'SKU *',
                prefixIcon: Icon(Icons.qr_code),
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'SKU is required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Map<String, dynamic>>(
              initialValue: _selectedCategory,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Category *',
                prefixIcon: Icon(Icons.category),
              ),
              items: _categories.map<DropdownMenuItem<Map<String, dynamic>>>((
                c,
              ) {
                return DropdownMenuItem(
                  value: c as Map<String, dynamic>,
                  child: Text(
                    '${c['name']} (${(c['type'] as String).replaceAll('_', ' ')})',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (c) => setState(() => _selectedCategory = c),
              validator: (v) => v == null ? 'Please select a category' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _unitController,
                    decoration: const InputDecoration(
                      labelText: 'Unit of Measure *',
                      prefixIcon: Icon(Icons.straighten),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _reorderController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Reorder Point',
                      prefixIcon: Icon(Icons.warning),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      final n = double.tryParse(v);
                      if (n == null || n < 0) return 'Must be ≥ 0';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              title: const Text('Active'),
              subtitle: const Text(
                'Inactive products are hidden from new sales/production but history is preserved.',
              ),
              secondary: Icon(
                _isActive ? Icons.check_circle : Icons.pause_circle,
                color: _isActive ? AppTheme.successColor : Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            _buildInventorySection(),
            const SizedBox(height: 16),
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
                  : const Icon(Icons.save),
              label: const Text('SAVE CHANGES'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
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

  Widget _buildInventorySection() {
    final inv = _inventoryItem;
    final qty = inv != null
        ? ((inv['currentQuantity'] as num?) ?? 0).toDouble()
        : 0.0;
    final unit = _unitController.text.isEmpty ? 'units' : _unitController.text;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: inv != null
            ? AppTheme.primaryLight.withValues(alpha: 0.4)
            : AppTheme.warningLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: inv != null
              ? AppTheme.primaryColor.withValues(alpha: 0.3)
              : AppTheme.warningColor.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                inv != null
                    ? Icons.inventory_2_rounded
                    : Icons.warning_amber_rounded,
                color: inv != null
                    ? AppTheme.primaryColor
                    : AppTheme.warningColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Inventory',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.slate900,
                ),
              ),
              const Spacer(),
              StatusBadge(
                label: inv != null ? 'TRACKED' : 'NOT TRACKED',
                color: inv != null
                    ? AppTheme.successColor
                    : AppTheme.warningColor,
                icon: inv != null ? Icons.check_circle : Icons.help_outline,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (inv != null)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Stock',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.slate500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${qty.toStringAsFixed(0)} $unit',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.slate900,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Value',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.slate500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ETB ${(inv['inventoryValue'] as num? ?? 0).toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.slate900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            const Text(
              'No inventory record exists for this product. Sales and production will fail without one.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.slate700,
                height: 1.4,
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (inv != null) {
                  context.push('/inventory/${inv['id']}');
                } else {
                  _createInitialStock();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: inv != null
                    ? AppTheme.primaryColor
                    : AppTheme.warningColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
              icon: Icon(
                inv != null ? Icons.tune_rounded : Icons.add_circle_outline,
                size: 18,
              ),
              label: Text(
                inv != null ? 'Adjust Stock' : 'Set Initial Stock',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
