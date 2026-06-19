import 'package:artemis_business_os/core/network/api_errors.dart';
import 'package:artemis_business_os/core/providers.dart';
import 'package:artemis_business_os/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class BomDetailScreen extends ConsumerStatefulWidget {
  final String bomId;

  const BomDetailScreen({super.key, required this.bomId});

  @override
  ConsumerState<BomDetailScreen> createState() => _BomDetailScreenState();
}

class _BomDetailScreenState extends ConsumerState<BomDetailScreen> {
  Map<String, dynamic>? _bom;
  bool _isLoading = true;
  String? _error;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('/production/boms/${widget.bomId}');
      setState(() {
        _bom = res.data as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = parseApiError(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleActive() async {
    if (_bom == null) return;
    setState(() => _isToggling = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.patch(
        '/production/boms/${widget.bomId}',
        data: {'isActive': !(_bom!['isActive'] as bool)},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              (_bom!['isActive'] as bool) ? 'BOM deactivated' : 'BOM activated',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
      await _load();
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
      if (mounted) setState(() => _isToggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BOM Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: List.generate(
          5,
          (i) => Card(
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(height: 60, color: Colors.white),
            ),
          ),
        ),
      );
    }
    if (_error != null || _bom == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(_error ?? 'BOM not found'),
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

    final bom = _bom!;
    final items = (bom['items'] as List? ?? []);
    final isActive = bom['isActive'] as bool;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: isActive
                ? AppTheme.successColor.withValues(alpha: 0.08)
                : Colors.grey.shade100,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          bom['finishedProductName'] as String? ?? 'Unknown',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.successColor : Colors.grey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isActive ? 'ACTIVE' : 'INACTIVE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'SKU: ${bom['finishedProductSku']}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricTile(
                          label: 'Version',
                          value: 'v${bom['version']}',
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricTile(
                          label: 'Materials',
                          value: '${items.length}',
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _kv('Effective from', _fmtDate(bom['effectiveDate'])),
                  if (bom['notes'] != null &&
                      (bom['notes'] as String).isNotEmpty)
                    _kv('Notes', bom['notes'] as String),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Materials (per ${bom['finishedProductSku'] ?? 'unit'})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.science,
                        size: 60,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 8),
                      const Text('No materials defined'),
                    ],
                  ),
                ),
              ),
            )
          else
            ...items.map<Widget>((m) {
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade100,
                    child: const Icon(
                      Icons.science,
                      color: Colors.orange,
                      size: 18,
                    ),
                  ),
                  title: Text(m['materialName'] as String? ?? 'Material'),
                  subtitle: Text(
                    'SKU: ${m['materialSku'] ?? '—'}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Text(
                    '${(m['quantity'] as num).toStringAsFixed(3)} ${m['unitOfMeasure'] ?? ''}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isToggling ? null : _toggleActive,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive
                        ? Colors.grey
                        : AppTheme.successColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: _isToggling
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          isActive ? Icons.pause_circle : Icons.check_circle,
                        ),
                  label: Text(isActive ? 'DEACTIVATE' : 'ACTIVATE'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            k,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            v,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );

  String _fmtDate(dynamic raw) {
    if (raw == null) return '—';
    try {
      return DateFormat(
        'MMM dd, yyyy',
      ).format(DateTime.parse(raw as String).toLocal());
    } catch (_) {
      return raw.toString();
    }
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
