import 'package:artemis_business_os/core/network/api_errors.dart';
import 'package:artemis_business_os/core/providers.dart';
import 'package:artemis_business_os/core/theme/app_theme.dart';
import 'package:artemis_business_os/core/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class EditBomScreen extends ConsumerStatefulWidget {
  final String bomId;

  const EditBomScreen({super.key, required this.bomId});

  @override
  ConsumerState<EditBomScreen> createState() => _EditBomScreenState();
}

class _EditBomScreenState extends ConsumerState<EditBomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _versionController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _effectiveDate = DateTime.now();
  bool _isActive = true;

  List<dynamic> _rawMaterials = [];
  List<_BomLine> _lines = [];
  bool _isLoadingProducts = true;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
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

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _isLoadingProducts = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final results = await Future.wait<dynamic>([
        api.get('/production/boms/${widget.bomId}'),
        api.get('/products', queryParameters: {'type': 'RAW_MATERIAL'}),
      ]);
      final bom = results[0].data as Map<String, dynamic>;
      final materials = results[1].data as List<dynamic>;
      _versionController.text = bom['version'] as String? ?? '';
      _notesController.text = bom['notes'] as String? ?? '';
      _isActive = bom['isActive'] as bool? ?? true;
      try {
        _effectiveDate = DateTime.parse(
          bom['effectiveDate'] as String,
        ).toLocal();
      } catch (_) {}

      // Populate lines from existing BOM items
      final existingItems = bom['items'] as List<dynamic>? ?? [];
      for (final item in existingItems) {
        final m = item as Map<String, dynamic>;
        _lines.add(
          _BomLine(
            initialMaterial: materials.firstWhere(
              (rm) =>
                  (rm as Map<String, dynamic>)['id'] == m['materialProductId'],
              orElse: () => {
                'id': m['materialProductId'],
                'name': m['materialName'] ?? 'Unknown',
                'unitOfMeasure': m['unitOfMeasure'] ?? '',
              },
            ),
            quantity: (m['quantity'] as num).toString(),
            onRemove: () => setState(
              () => _lines.removeWhere(
                (l) => l.material?['id'] == m['materialProductId'],
              ),
            ),
          ),
        );
      }
      setState(() {
        _rawMaterials = materials;
        _isLoadingProducts = false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = parseApiError(e);
        _isLoading = false;
        _isLoadingProducts = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lines.isEmpty) {
      showAppSnackBar(
        context,
        message: 'Please add at least one material',
        isError: true,
      );
      return;
    }
    if (_lines.any((l) => l.material == null)) {
      showAppSnackBar(
        context,
        message: 'All materials must be selected',
        isError: true,
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.patch(
        '/production/boms/${widget.bomId}',
        data: {
          'version': _versionController.text.trim(),
          'effectiveDate': _effectiveDate.toIso8601String(),
          'notes': _notesController.text.trim(),
          'isActive': _isActive,
          'items': _lines
              .map(
                (l) => {
                  'materialProductId': l.material!['id'] as String,
                  'quantity': double.parse(l.quantityController.text),
                },
              )
              .toList(),
        },
      );
      if (mounted) {
        showAppSnackBar(context, message: 'BOM updated', isSuccess: true);
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

  void _addLine() {
    if (_rawMaterials.isEmpty) {
      showAppSnackBar(
        context,
        message: 'No raw materials available',
        isError: true,
      );
      return;
    }
    setState(() {
      _lines.add(
        _BomLine(onRemove: () => setState(() => _lines.remove(_lines.last))),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _isLoadingProducts) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit BOM')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit BOM')),
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
        title: const Text('Edit BOM'),
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
              controller: _versionController,
              decoration: const InputDecoration(
                labelText: 'Version *',
                prefixIcon: Icon(Icons.numbers),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Version is required' : null,
            ),
            const SizedBox(height: 16),
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
            SwitchListTile(
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              title: const Text('Active'),
              subtitle: const Text(
                'Activating will deactivate the prior version of this BOM.',
              ),
              secondary: Icon(
                _isActive ? Icons.check_circle : Icons.pause_circle,
                color: _isActive ? AppTheme.successColor : Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
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
                        const Text('No materials'),
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
  final TextEditingController quantityController;
  final VoidCallback onRemove;

  _BomLine({
    String quantity = '1',
    Map<String, dynamic>? initialMaterial,
    required this.onRemove,
  }) : material = initialMaterial,
       quantityController = TextEditingController(text: quantity);

  void dispose() {
    quantityController.dispose();
  }
}
