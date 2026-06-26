import 'package:artemis_business_os/core/network/api_errors.dart';
import 'package:artemis_business_os/core/providers.dart';
import 'package:artemis_business_os/core/theme/app_theme.dart';
import 'package:artemis_business_os/core/widgets/confirm_dialog.dart';
import 'package:artemis_business_os/core/widgets/ui_pro.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class CreatePurchaseOrderScreen extends ConsumerStatefulWidget {
  final String? supplierId;
  const CreatePurchaseOrderScreen({super.key, this.supplierId});

  @override
  ConsumerState<CreatePurchaseOrderScreen> createState() =>
      _CreatePurchaseOrderScreenState();
}

class _CreatePurchaseOrderScreenState
    extends ConsumerState<CreatePurchaseOrderScreen> {
  List<dynamic> _suppliers = [];
  List<dynamic> _products = [];
  Map<String, dynamic>? _selectedSupplier;
  final List<_POItem> _items = [];
  final _notesController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final i in _items) {
      i.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final api = ref.read(apiClientProvider);
      final results = await Future.wait([
        api.get('/suppliers'),
        api.get('/products'),
      ]);
      if (!mounted) return;
      setState(() {
        _suppliers = (results[0].data as List)
            .where((s) => s['isActive'] == true)
            .toList();
        _products = (results[1].data as List)
            .where((p) => p['isActive'] == true)
            .toList();
        if (widget.supplierId != null) {
          _selectedSupplier = _suppliers.firstWhere(
            (s) => s['id'] == widget.supplierId,
            orElse: () => null,
          );
        }
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addItem(Map<String, dynamic> product) {
    if (_items.any((i) => i.productId == product['id'])) return;
    setState(() {
      _items.add(_POItem(product: product));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  double get _total => _items.fold(0, (sum, i) => sum + (i.qty * i.unitCost));

  Future<void> _save() async {
    if (_selectedSupplier == null) {
      showAppSnackBar(context, message: 'Select a supplier', isError: true);
      return;
    }
    if (_items.isEmpty) {
      showAppSnackBar(context, message: 'Add at least one item', isError: true);
      return;
    }
    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post(
        '/purchase-orders',
        data: {
          'supplierId': _selectedSupplier!['id'],
          'notes': _notesController.text.trim(),
          'items': _items
              .map(
                (i) => {
                  'productId': i.productId,
                  'quantity': i.qty,
                  'unitCost': i.unitCost,
                },
              )
              .toList(),
        },
      );
      if (mounted) {
        showAppSnackBar(
          context,
          message: 'Purchase order created!',
          isSuccess: true,
        );
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('New Purchase Order')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: AppTheme.slate50,
      appBar: AppBar(
        title: const Text('New Purchase Order'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                GlassCard(
                  accentColor: const Color(0xFF0F766E),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeaderPro(
                        title: 'Supplier',
                        icon: Icons.business_rounded,
                        accentColor: Color(0xFF0F766E),
                      ),
                      DropdownButtonFormField<Map<String, dynamic>>(
                        initialValue: _selectedSupplier,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Choose Supplier *',
                          prefixIcon: Icon(Icons.business_rounded),
                        ),
                        items: _suppliers
                            .map<DropdownMenuItem<Map<String, dynamic>>>((s) {
                              return DropdownMenuItem(
                                value: s as Map<String, dynamic>,
                                child: Text(s['name'] as String),
                              );
                            })
                            .toList(),
                        onChanged: (s) => setState(() => _selectedSupplier = s),
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_selectedSupplier != null) ...[
                  GlassCard(
                    accentColor: AppTheme.warningColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeaderPro(
                          title: 'Items',
                          subtitle:
                              '${_items.length} item${_items.length == 1 ? '' : 's'}',
                          icon: Icons.inventory_2_rounded,
                          accentColor: AppTheme.warningColor,
                        ),
                        if (_items.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.slate50,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMd,
                              ),
                              border: Border.all(
                                color: AppTheme.slate200,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'Tap a product below to add',
                                style: TextStyle(
                                  color: AppTheme.slate500,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                        else
                          ..._items.asMap().entries.map((entry) {
                            final i = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _POItemRow(
                                item: i,
                                onRemove: () => _removeItem(entry.key),
                                onChanged: () => setState(() {}),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassCard(
                    accentColor: AppTheme.infoColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeaderPro(
                          title: 'Add Products',
                          icon: Icons.add_box_rounded,
                          accentColor: AppTheme.infoColor,
                        ),
                        SizedBox(
                          height: 56,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _products.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (ctx, i) {
                              final p = _products[i] as Map<String, dynamic>;
                              final alreadyAdded = _items.any(
                                (it) => it.productId == p['id'],
                              );
                              return FilterChip(
                                label: Text(p['name'] as String),
                                selected: alreadyAdded,
                                onSelected: alreadyAdded
                                    ? null
                                    : (_) => _addItem(p),
                                selectedColor: AppTheme.successLight,
                                checkmarkColor: AppTheme.successColor,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassCard(
                    accentColor: AppTheme.accentColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeaderPro(
                          title: 'Notes',
                          icon: Icons.note_rounded,
                          accentColor: AppTheme.accentColor,
                        ),
                        TextField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Notes (Optional)',
                            hintText: 'Delivery instructions, etc...',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
          Container(
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
                        const Text(
                          'TOTAL',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.slate500,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          'ETB ${NumberFormat.decimalPattern().format(_total)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.slate900,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
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
                          : const Icon(Icons.check_circle_rounded),
                      label: const Text(
                        'Create PO',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _POItem {
  final String productId;
  final TextEditingController qtyController;
  final TextEditingController costController;
  Map<String, dynamic> product;

  _POItem({required this.product})
    : productId = product['id'] as String,
      qtyController = TextEditingController(text: '1'),
      costController = TextEditingController(
        text: product['unitCost']?.toString() ?? '0',
      );

  double get qty => double.tryParse(qtyController.text) ?? 0;
  double get unitCost => double.tryParse(costController.text) ?? 0;
  String get unit => product['unitOfMeasure'] as String? ?? '';

  void dispose() {
    qtyController.dispose();
    costController.dispose();
  }
}

class _POItemRow extends StatelessWidget {
  final _POItem item;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  const _POItemRow({
    required this.item,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.slate50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.warningLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.science_rounded,
                  color: AppTheme.warningColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product['name'] as String,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.slate900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'SKU ${item.product['sku']}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.slate500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: AppTheme.dangerColor,
                onPressed: onRemove,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: item.qtyController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Qty',
                    isDense: true,
                    suffixText: item.unit,
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: item.costController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Unit Cost',
                    prefixText: 'ETB ',
                    isDense: true,
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  alignment: Alignment.centerRight,
                  child: Text(
                    'ETB ${(item.qty * item.unitCost).toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
