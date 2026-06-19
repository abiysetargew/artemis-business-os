import 'package:artemis_business_os/core/providers.dart';
import 'package:artemis_business_os/core/theme/app_theme.dart';
import 'package:artemis_business_os/features/auth/application/auth_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class PaymentDetailScreen extends ConsumerStatefulWidget {
  final String paymentId;

  const PaymentDetailScreen({super.key, required this.paymentId});

  @override
  ConsumerState<PaymentDetailScreen> createState() =>
      _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends ConsumerState<PaymentDetailScreen> {
  Map<String, dynamic>? _payment;
  bool _isLoading = true;
  String? _error;
  bool _isVerifying = false;

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
      final res = await api.get('/payments/${widget.paymentId}');
      setState(() {
        _payment = res.data as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load payment';
        _isLoading = false;
      });
    }
  }

  Future<void> _verify(String status) async {
    setState(() => _isVerifying = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post(
        '/payments/${widget.paymentId}/verify',
        data: {'status': status, 'notes': null},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment ${status.toLowerCase()}'),
            backgroundColor: status == 'VERIFIED'
                ? AppTheme.successColor
                : Colors.red,
          ),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Color _statusColor(String s) => s == 'VERIFIED'
      ? AppTheme.successColor
      : s == 'REJECTED'
      ? Colors.red
      : Colors.orange;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Details'),
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
          (index) => Card(
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(height: 60, color: Colors.white),
            ),
          ),
        ),
      );
    }
    if (_error != null || _payment == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(_error ?? 'Payment not found'),
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

    final p = _payment!;
    final status = p['verificationStatus'] as String;
    final color = _statusColor(status);
    final currency = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 2);
    final isAdmin = ref.read(authNotifierProvider).user?.isAdmin ?? false;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: color.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        currency.format(p['amount']),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p['customerName'] as String? ?? 'Customer',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _DetailCard(
            title: 'Payment Information',
            entries: [
              _DetailEntry('Date', _formatDate(p['paymentDate'])),
              _DetailEntry('Method', p['paymentMethod'] as String),
              if (p['referenceNumber'] != null)
                _DetailEntry('Reference', p['referenceNumber'] as String),
              if (p['salesOrderNumber'] != null)
                _DetailEntry('Sales Order', p['salesOrderNumber'] as String),
              _DetailEntry('Recorded by', p['userName'] as String? ?? '—'),
            ],
          ),
          const SizedBox(height: 12),
          if (p['notes'] != null && (p['notes'] as String).isNotEmpty)
            _DetailCard(
              title: 'Notes',
              entries: [_DetailEntry('', p['notes'] as String)],
            ),
          if (p['verification'] != null) ...[
            const SizedBox(height: 12),
            _DetailCard(
              title: 'Verification',
              entries: [
                _DetailEntry('Status', p['verification']['status'] as String),
                _DetailEntry(
                  'Verified by',
                  p['verification']['verifierName'] as String? ?? '—',
                ),
                _DetailEntry(
                  'Date',
                  _formatDate(p['verification']['verificationDate']),
                ),
                if (p['verification']['notes'] != null)
                  _DetailEntry('Notes', p['verification']['notes'] as String),
              ],
            ),
          ],
          if (isAdmin && status == 'PENDING') ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isVerifying ? null : () => _verify('REJECTED'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.cancel),
                    label: const Text('REJECT'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isVerifying ? null : () => _verify('VERIFIED'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: _isVerifying
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle),
                    label: const Text('VERIFY'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '—';
    try {
      return DateFormat(
        'MMM dd, yyyy • HH:mm',
      ).format(DateTime.parse(raw as String).toLocal());
    } catch (_) {
      return raw.toString();
    }
  }
}

class _DetailEntry {
  final String label;
  final String value;

  const _DetailEntry(this.label, this.value);
}

class _DetailCard extends StatelessWidget {
  final String title;
  final List<_DetailEntry> entries;

  const _DetailCard({required this.title, required this.entries});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 12),
            ...entries.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: e.label.isEmpty
                    ? Text(e.value, style: const TextStyle(fontSize: 13))
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 120,
                            child: Text(
                              e.label,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              e.value,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
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
